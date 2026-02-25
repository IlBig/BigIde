#!/usr/bin/env node
// OAuth PKCE flow per Google Gemini — standalone, zero dipendenze esterne.
// Estratto da BigBot/idee/openclaw/extensions/google-gemini-cli-auth/oauth.ts
//
// Uso:
//   node oauth-gemini.mjs login     # Flusso OAuth completo (estrae creds da gemini CLI)
//   node oauth-gemini.mjs refresh   # Rinnova token esistente
//   node oauth-gemini.mjs status    # Mostra stato token corrente
//   node oauth-gemini.mjs ensure    # Verifica/rinnova silenziosamente
//
// Formato output (~/.gemini/auth.json):
//   { "tokens": { "access_token": "...", "refresh_token": "..." },
//     "expires_at": <epoch_ms>, "email": "...", "project_id": "..." }
//
// Credenziali OAuth client: estratte automaticamente dal Gemini CLI installato,
// oppure da env GEMINI_CLI_OAUTH_CLIENT_ID / GEMINI_CLI_OAUTH_CLIENT_SECRET.

import { createHash, randomBytes } from 'node:crypto';
import * as http from 'node:http';
import { readFileSync, writeFileSync, mkdirSync, existsSync, readdirSync, realpathSync } from 'node:fs';
import { join, dirname, delimiter } from 'node:path';
import { homedir } from 'node:os';
import { execSync } from 'node:child_process';
import { createInterface } from 'node:readline';

// ── Costanti OAuth Google ──────────────────────────────────────────────────────
const AUTH_URL           = 'https://accounts.google.com/o/oauth2/v2/auth';
const TOKEN_URL          = 'https://oauth2.googleapis.com/token';
const USERINFO_URL       = 'https://www.googleapis.com/oauth2/v1/userinfo?alt=json';
const CODE_ASSIST_URL    = 'https://cloudcode-pa.googleapis.com';
const CALLBACK_PORT      = 8085;
// 127.0.0.1 invece di localhost: Safari converte localhost in HTTPS (HSTS)
const REDIRECT_URI       = `http://127.0.0.1:${CALLBACK_PORT}/oauth2callback`;
const SCOPES             = [
  'https://www.googleapis.com/auth/cloud-platform',
  'https://www.googleapis.com/auth/userinfo.email',
  'https://www.googleapis.com/auth/userinfo.profile',
].join(' ');
const REFRESH_BUFFER_MS  = 5 * 60 * 1000;
const OAUTH_TIMEOUT_MS   = 5 * 60 * 1000;

const AUTH_DIR  = join(homedir(), '.gemini');
const AUTH_FILE = join(AUTH_DIR, 'auth.json');

// ── Estrazione credenziali dal Gemini CLI installato ───────────────────────────

function findInPath(name) {
  const exts = process.platform === 'win32' ? ['.cmd', '.bat', '.exe', ''] : [''];
  for (const dir of (process.env.PATH ?? '').split(delimiter)) {
    for (const ext of exts) {
      const p = join(dir, name + ext);
      if (existsSync(p)) return p;
    }
  }
  return null;
}

function findFile(dir, name, depth) {
  if (depth <= 0) return null;
  try {
    for (const e of readdirSync(dir, { withFileTypes: true })) {
      const p = join(dir, e.name);
      if (e.isFile() && e.name === name) return p;
      if (e.isDirectory() && !e.name.startsWith('.')) {
        const found = findFile(p, name, depth - 1);
        if (found) return found;
      }
    }
  } catch { /* ignore */ }
  return null;
}

function extractGeminiCliCredentials() {
  try {
    const geminiPath = findInPath('gemini');
    if (!geminiPath) return null;

    const resolvedPath = realpathSync(geminiPath);
    const geminiCliDir = dirname(dirname(resolvedPath));

    const searchPaths = [
      join(geminiCliDir, 'node_modules', '@google', 'gemini-cli-core', 'dist', 'src', 'code_assist', 'oauth2.js'),
      join(geminiCliDir, 'node_modules', '@google', 'gemini-cli-core', 'dist', 'code_assist', 'oauth2.js'),
    ];

    let content = null;
    for (const p of searchPaths) {
      if (existsSync(p)) {
        content = readFileSync(p, 'utf8');
        break;
      }
    }
    if (!content) {
      const found = findFile(geminiCliDir, 'oauth2.js', 10);
      if (found) content = readFileSync(found, 'utf8');
    }
    if (!content) return null;

    const idMatch = content.match(/(\d+-[a-z0-9]+\.apps\.googleusercontent\.com)/);
    const secretMatch = content.match(/(GOCSPX-[A-Za-z0-9_-]+)/);
    if (idMatch && secretMatch) {
      return { clientId: idMatch[1], clientSecret: secretMatch[1] };
    }
  } catch { /* ignore */ }
  return null;
}

function resolveOAuthClientConfig() {
  // 1. Env vars (override utente)
  const envId = process.env.GEMINI_CLI_OAUTH_CLIENT_ID?.trim()
    || process.env.OPENCLAW_GEMINI_OAUTH_CLIENT_ID?.trim();
  const envSecret = process.env.GEMINI_CLI_OAUTH_CLIENT_SECRET?.trim()
    || process.env.OPENCLAW_GEMINI_OAUTH_CLIENT_SECRET?.trim();
  if (envId) {
    return { clientId: envId, clientSecret: envSecret };
  }

  // 2. Estrai dal Gemini CLI installato
  const extracted = extractGeminiCliCredentials();
  if (extracted) return extracted;

  // 3. Non disponibili
  throw new Error(
    'Gemini CLI non trovato. Installalo prima: brew install gemini-cli (o npm i -g @google/gemini-cli),\n'
    + 'oppure imposta GEMINI_CLI_OAUTH_CLIENT_ID e GEMINI_CLI_OAUTH_CLIENT_SECRET.',
  );
}

// ── Utilità PKCE ───────────────────────────────────────────────────────────────

function generatePkce() {
  const verifier  = randomBytes(32).toString('hex');
  const challenge = createHash('sha256').update(verifier).digest('base64url');
  return { verifier, challenge };
}

function buildAuthorizeUrl(pkce) {
  const { clientId } = resolveOAuthClientConfig();
  const url = new URL(AUTH_URL);
  url.searchParams.set('client_id', clientId);
  url.searchParams.set('response_type', 'code');
  url.searchParams.set('redirect_uri', REDIRECT_URI);
  url.searchParams.set('scope', SCOPES);
  url.searchParams.set('code_challenge', pkce.challenge);
  url.searchParams.set('code_challenge_method', 'S256');
  url.searchParams.set('state', pkce.verifier);
  url.searchParams.set('access_type', 'offline');
  url.searchParams.set('prompt', 'consent');
  return url.toString();
}

// ── Token exchange ─────────────────────────────────────────────────────────────

async function exchangeCode(code, verifier) {
  const { clientId, clientSecret } = resolveOAuthClientConfig();
  const body = new URLSearchParams({
    client_id:     clientId,
    code,
    grant_type:    'authorization_code',
    redirect_uri:  REDIRECT_URI,
    code_verifier: verifier,
  });
  if (clientSecret) body.set('client_secret', clientSecret);

  const res = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Token exchange fallito (${res.status}): ${text}`);
  }
  const data = await res.json();
  if (!data.access_token || !data.refresh_token) {
    throw new Error('Risposta token Google incompleta (manca refresh_token). Riprova.');
  }
  return {
    access_token:  data.access_token,
    refresh_token: data.refresh_token,
    expires_at:    Date.now() + data.expires_in * 1000 - REFRESH_BUFFER_MS,
  };
}

async function refreshToken(currentRefreshToken) {
  const { clientId, clientSecret } = resolveOAuthClientConfig();
  const body = new URLSearchParams({
    client_id:     clientId,
    grant_type:    'refresh_token',
    refresh_token: currentRefreshToken,
  });
  if (clientSecret) body.set('client_secret', clientSecret);

  const res = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Token refresh fallito (${res.status}): ${text}`);
  }
  const data = await res.json();
  if (!data.access_token || !data.expires_in) {
    throw new Error('Risposta refresh Google incompleta');
  }
  return {
    access_token:  data.access_token,
    refresh_token: data.refresh_token ?? currentRefreshToken,
    expires_at:    Date.now() + data.expires_in * 1000 - REFRESH_BUFFER_MS,
  };
}

// ── User info + project discovery ──────────────────────────────────────────────

async function getUserEmail(accessToken) {
  try {
    const res = await fetch(USERINFO_URL, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    if (res.ok) {
      const data = await res.json();
      return data.email;
    }
  } catch { /* ignore */ }
  return undefined;
}

async function discoverProject(accessToken) {
  const envProject = process.env.GOOGLE_CLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT_ID;
  const headers = {
    Authorization: `Bearer ${accessToken}`,
    'Content-Type': 'application/json',
    'User-Agent': 'google-api-nodejs-client/9.15.1',
    'X-Goog-Api-Client': 'gl-node/bigide',
  };

  try {
    const res = await fetch(`${CODE_ASSIST_URL}/v1internal:loadCodeAssist`, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        cloudaicompanionProject: envProject,
        metadata: { ideType: 'IDE_UNSPECIFIED', platform: 'PLATFORM_UNSPECIFIED', pluginType: 'GEMINI', duetProject: envProject },
      }),
    });

    if (res.ok) {
      const data = await res.json();
      if (data.currentTier) {
        const project = data.cloudaicompanionProject;
        if (typeof project === 'string' && project) return project;
        if (typeof project === 'object' && project?.id) return project.id;
      }

      // Onboard se necessario
      const tier = data.allowedTiers?.find(t => t.isDefault)?.id || 'free-tier';
      const onboardRes = await fetch(`${CODE_ASSIST_URL}/v1internal:onboardUser`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          tierId: tier,
          metadata: { ideType: 'IDE_UNSPECIFIED', platform: 'PLATFORM_UNSPECIFIED', pluginType: 'GEMINI' },
        }),
      });

      if (onboardRes.ok) {
        let lro = await onboardRes.json();
        // Poll se operazione asincrona
        if (!lro.done && lro.name) {
          for (let i = 0; i < 24; i++) {
            await new Promise(r => setTimeout(r, 5000));
            const pollRes = await fetch(`${CODE_ASSIST_URL}/v1internal/${lro.name}`, { headers });
            if (pollRes.ok) {
              lro = await pollRes.json();
              if (lro.done) break;
            }
          }
        }
        const projectId = lro.response?.cloudaicompanionProject?.id;
        if (projectId) return projectId;
      }
    }
  } catch (err) {
    // Project discovery non critico — logga e continua
    console.error(`  Avviso: project discovery fallito (${err.message})`);
  }

  return envProject || '';
}

// ── Persistenza ────────────────────────────────────────────────────────────────

function saveTokens(tokens, email, projectId) {
  mkdirSync(AUTH_DIR, { recursive: true });
  const payload = {
    tokens: {
      access_token:  tokens.access_token,
      refresh_token: tokens.refresh_token,
    },
    expires_at: tokens.expires_at,
    email:      email || '',
    project_id: projectId || '',
  };
  writeFileSync(AUTH_FILE, JSON.stringify(payload, null, 2) + '\n', { mode: 0o600 });
}

function loadTokens() {
  try {
    return JSON.parse(readFileSync(AUTH_FILE, 'utf-8'));
  } catch {
    return null;
  }
}

// ── HTML callback ──────────────────────────────────────────────────────────────
const SUCCESS_HTML = `<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>BigIDE — Google connesso</title>
<style>
  body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;
    background:#1a1b26;color:#c0caf5;display:flex;flex-direction:column;
    align-items:center;justify-content:center;min-height:100vh;gap:16px;margin:0}
  .check{width:64px;height:64px;border-radius:50%;background:#9ece6a;display:flex;
    align-items:center;justify-content:center;font-size:32px;color:#1a1b26}
  h2{margin:0;font-size:20px}
  p{color:#565f89;font-size:14px;margin:0;text-align:center}
</style></head><body>
  <div class="check">&#10003;</div>
  <h2>Google Gemini connesso!</h2>
  <p>Autenticazione completata. Puoi chiudere questa finestra.</p>
</body></html>`;

// ── Helpers browser ────────────────────────────────────────────────────────────

// Safari ha HSTS su localhost (converte http→https). Prova Chrome/Firefox prima.
function openBrowser(url) {
  const browsers = [
    'Google Chrome',
    'Firefox',
    'Brave Browser',
    'Microsoft Edge',
  ];
  for (const app of browsers) {
    try {
      execSync(`open -a "${app}" "${url}"`, { stdio: 'ignore' });
      return app;
    } catch { /* non installato */ }
  }
  // Fallback: browser di default (potrebbe essere Safari con HSTS)
  try {
    execSync(`open "${url}"`, { stdio: 'ignore' });
    return 'default';
  } catch {
    return null;
  }
}

function prompt(question) {
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

function extractCodeFromUrl(input, expectedState) {
  const trimmed = input.trim();
  try {
    const url = new URL(trimmed.startsWith('http') ? trimmed : `http://dummy?${trimmed}`);
    const code = url.searchParams.get('code');
    const state = url.searchParams.get('state');
    if (code && (!state || state === expectedState)) return code;
  } catch { /* non è un URL */ }
  return null;
}

// ── Flusso OAuth login ─────────────────────────────────────────────────────────

function login() {
  return new Promise((resolve, reject) => {
    const pkce = generatePkce();
    const authorizeUrl = buildAuthorizeUrl(pkce);
    let settled = false;

    function finish(err, result) {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      try { server.close(); } catch {}
      if (err) reject(err); else resolve(result);
    }

    async function handleCode(code) {
      console.log('Scambio codice per token...');
      const tokens = await exchangeCode(code, pkce.verifier);

      console.log('Recupero info utente...');
      const email = await getUserEmail(tokens.access_token);

      console.log('Discovery progetto Google Cloud...');
      const projectId = await discoverProject(tokens.access_token);

      saveTokens(tokens, email, projectId);
      finish(null, { ...tokens, email, projectId });
    }

    const server = http.createServer(async (req, res) => {
      const url = new URL(req.url ?? '/', 'http://localhost');

      if (url.pathname !== '/oauth2callback') {
        res.writeHead(404, { 'Content-Type': 'text/plain' }).end('Not found');
        return;
      }

      const oauthError = url.searchParams.get('error');
      const code       = url.searchParams.get('code');
      const state      = url.searchParams.get('state');

      if (oauthError) {
        res.writeHead(400, { 'Content-Type': 'text/plain' }).end(`Errore OAuth: ${oauthError}`);
        finish(new Error(oauthError));
        return;
      }

      if (!code || state !== pkce.verifier) {
        res.writeHead(400, { 'Content-Type': 'text/plain' }).end('Invalid request');
        return;
      }

      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' }).end(SUCCESS_HTML);

      try { await handleCode(code); } catch (e) { finish(e); }
    });

    const timer = setTimeout(() => {
      finish(new Error('Timeout: OAuth non completato entro 5 minuti'));
    }, OAUTH_TIMEOUT_MS);

    server.listen(CALLBACK_PORT, '127.0.0.1', () => {
      console.log(`\x1b[34mGoogle Gemini OAuth PKCE\x1b[0m`);
      console.log(`Server callback in ascolto su porta ${CALLBACK_PORT}`);
      console.log();

      const browser = openBrowser(authorizeUrl);
      if (browser && browser !== 'default') {
        console.log(`Browser aperto (${browser}). Completa il login con il tuo account Google...`);
      } else if (browser === 'default') {
        console.log('Browser aperto. Completa il login con il tuo account Google...');
      } else {
        console.log('Apri questo URL nel browser:');
        console.log();
        console.log(`  ${authorizeUrl}`);
      }

      console.log();
      console.log('In attesa del callback automatico...');
      console.log();
      console.log(`\x1b[33mSe il browser mostra errore HTTPS/connessione:`);
      console.log(`copia l'URL dalla barra degli indirizzi e incollalo qui.\x1b[0m`);
      console.log();

      // Fallback manuale: accetta URL incollato da stdin
      (async () => {
        const input = await prompt('(oppure incolla URL qui): ');
        if (settled) return;
        if (!input) return;
        const code = extractCodeFromUrl(input, pkce.verifier);
        if (code) {
          console.log();
          console.log('Codice estratto dall\'URL. Scambio token...');
          try { await handleCode(code); } catch (e) { finish(e); }
        } else {
          console.log('\x1b[31mURL non valido. Attendo callback...\x1b[0m');
        }
      })();
    });
  });
}

// ── Comando refresh ────────────────────────────────────────────────────────────
async function doRefresh() {
  const stored = loadTokens();
  if (!stored?.tokens?.refresh_token) {
    console.error('Nessun token salvato. Esegui prima: oauth-gemini.mjs login');
    process.exit(1);
  }

  console.log('Rinnovo token Google...');
  const tokens = await refreshToken(stored.tokens.refresh_token);
  saveTokens(tokens, stored.email, stored.project_id);
  console.log(`Token rinnovato. Scade: ${new Date(tokens.expires_at).toLocaleString()}`);
}

// ── Comando status ─────────────────────────────────────────────────────────────
function showStatus() {
  const stored = loadTokens();
  if (!stored) {
    console.log('Nessun token Google Gemini salvato.');
    console.log(`File atteso: ${AUTH_FILE}`);
    process.exit(1);
  }

  const now = Date.now();
  const expired = now > stored.expires_at;
  const remaining = expired ? 0 : Math.round((stored.expires_at - now) / 60000);

  console.log(`\x1b[34mGoogle Gemini OAuth Status\x1b[0m`);
  console.log(`File:       ${AUTH_FILE}`);
  console.log(`Email:      ${stored.email || '(sconosciuto)'}`);
  console.log(`Progetto:   ${stored.project_id || '(nessuno)'}`);
  console.log(`Scadenza:   ${new Date(stored.expires_at).toLocaleString()}`);
  console.log(`Stato:      ${expired ? '\x1b[31mSCADUTO\x1b[0m' : `\x1b[32mValido\x1b[0m (${remaining} min rimanenti)`}`);

  if (expired) {
    console.log();
    console.log('Esegui: oauth-gemini.mjs refresh');
  }
}

// ── Comando ensure ─────────────────────────────────────────────────────────────
async function ensureValid() {
  const stored = loadTokens();
  if (!stored?.tokens?.refresh_token) {
    process.exit(1);
  }
  if (Date.now() < stored.expires_at) {
    process.exit(0);
  }
  try {
    const tokens = await refreshToken(stored.tokens.refresh_token);
    saveTokens(tokens, stored.email, stored.project_id);
    process.exit(0);
  } catch {
    process.exit(1);
  }
}

// ── Main ───────────────────────────────────────────────────────────────────────
const command = process.argv[2] ?? 'login';

switch (command) {
  case 'login':
    try {
      const result = await login();
      console.log();
      console.log(`\x1b[32mLogin completato!\x1b[0m`);
      console.log(`Token salvato in: ${AUTH_FILE}`);
      console.log(`Email:     ${result.email || '(sconosciuto)'}`);
      console.log(`Progetto:  ${result.projectId || '(nessuno)'}`);
      console.log(`Scadenza:  ${new Date(result.expires_at).toLocaleString()}`);
    } catch (err) {
      console.error(`\x1b[31mErrore:\x1b[0m ${err.message}`);
      process.exit(1);
    }
    break;

  case 'refresh':
    try {
      await doRefresh();
    } catch (err) {
      console.error(`\x1b[31mErrore refresh:\x1b[0m ${err.message}`);
      console.log('Potrebbe servire un nuovo login: oauth-gemini.mjs login');
      process.exit(1);
    }
    break;

  case 'status':
    showStatus();
    break;

  case 'ensure':
    await ensureValid();
    break;

  default:
    console.log('Uso: oauth-gemini.mjs <login|refresh|status|ensure>');
    process.exit(1);
}

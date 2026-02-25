#!/usr/bin/env node
// OAuth PKCE flow per OpenAI Codex — standalone, zero dipendenze esterne.
// Estratto da BigBot/src/setup/oauth-openai.ts e adattato per CLI.
//
// Uso:
//   node oauth-openai.mjs login     # Flusso OAuth completo → salva ~/.codex/auth.json
//   node oauth-openai.mjs refresh   # Rinnova token esistente
//   node oauth-openai.mjs status    # Mostra stato token corrente
//
// Formato output (~/.codex/auth.json):
//   { "tokens": { "access_token": "...", "refresh_token": "..." }, "expires_at": <epoch_ms>, "account_id": "..." }

import { createHash, randomBytes } from 'node:crypto';
import * as http from 'node:http';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { homedir } from 'node:os';
import { execSync } from 'node:child_process';
import { createInterface } from 'node:readline';

// ── Costanti OAuth OpenAI ──────────────────────────────────────────────────────
const CLIENT_ID     = 'app_EMoamEEZ73f0CkXaXp7hrann';
const AUTHORIZE_URL = 'https://auth.openai.com/oauth/authorize';
const TOKEN_URL     = 'https://auth.openai.com/oauth/token';
const CALLBACK_PORT = 1455;
// localhost obbligatorio: il client_id OpenAI accetta solo localhost
const REDIRECT_URI  = `http://localhost:${CALLBACK_PORT}/auth/callback`;
const SCOPE         = 'openid profile email offline_access';
const REFRESH_BUFFER_MS = 5 * 60 * 1000; // 5 minuti
const OAUTH_TIMEOUT_MS  = 10 * 60 * 1000; // 10 minuti

const AUTH_DIR  = join(homedir(), '.codex');
const AUTH_FILE = join(AUTH_DIR, 'auth.json');

// ── Utilità ────────────────────────────────────────────────────────────────────
function base64url(buf) {
  return buf.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

function generatePkce() {
  const verifier  = base64url(randomBytes(32));
  const challenge = base64url(createHash('sha256').update(verifier).digest());
  const state     = randomBytes(16).toString('hex');
  return { verifier, challenge, state };
}

function buildAuthorizeUrl(pkce) {
  const url = new URL(AUTHORIZE_URL);
  url.searchParams.set('response_type', 'code');
  url.searchParams.set('client_id', CLIENT_ID);
  url.searchParams.set('redirect_uri', REDIRECT_URI);
  url.searchParams.set('scope', SCOPE);
  url.searchParams.set('code_challenge', pkce.challenge);
  url.searchParams.set('code_challenge_method', 'S256');
  url.searchParams.set('state', pkce.state);
  url.searchParams.set('id_token_add_organizations', 'true');
  url.searchParams.set('codex_cli_simplified_flow', 'true');
  return url.toString();
}

function extractAccountId(accessToken) {
  try {
    const payload = JSON.parse(
      Buffer.from(accessToken.split('.')[1], 'base64url').toString(),
    );
    const auth = payload['https://api.openai.com/auth'];
    return auth?.chatgpt_account_id ?? '';
  } catch {
    return '';
  }
}

// ── Token exchange ─────────────────────────────────────────────────────────────
async function exchangeCode(code, verifier) {
  const res = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type:    'authorization_code',
      client_id:     CLIENT_ID,
      code,
      code_verifier: verifier,
      redirect_uri:  REDIRECT_URI,
    }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Token exchange fallito (${res.status}): ${text}`);
  }
  const data = await res.json();
  if (!data.access_token || !data.refresh_token || !data.expires_in) {
    throw new Error('Risposta token OpenAI incompleta');
  }
  return {
    access_token:  data.access_token,
    refresh_token: data.refresh_token,
    expires_at:    Date.now() + data.expires_in * 1000 - REFRESH_BUFFER_MS,
    account_id:    extractAccountId(data.access_token),
  };
}

async function refreshToken(currentRefreshToken) {
  const res = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type:    'refresh_token',
      refresh_token: currentRefreshToken,
      client_id:     CLIENT_ID,
    }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Token refresh fallito (${res.status}): ${text}`);
  }
  const data = await res.json();
  if (!data.access_token || !data.expires_in) {
    throw new Error('Risposta refresh OpenAI incompleta');
  }
  return {
    access_token:  data.access_token,
    refresh_token: data.refresh_token ?? currentRefreshToken,
    expires_at:    Date.now() + data.expires_in * 1000 - REFRESH_BUFFER_MS,
    account_id:    extractAccountId(data.access_token),
  };
}

// ── Persistenza ────────────────────────────────────────────────────────────────
function saveTokens(tokens) {
  mkdirSync(AUTH_DIR, { recursive: true });
  const payload = {
    tokens: {
      access_token:  tokens.access_token,
      refresh_token: tokens.refresh_token,
    },
    expires_at: tokens.expires_at,
    account_id: tokens.account_id,
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
<html><head><meta charset="UTF-8"><title>BigIDE — OpenAI connesso</title>
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
  <h2>OpenAI connesso!</h2>
  <p>Autenticazione completata. Puoi chiudere questa finestra.</p>
</body></html>`;

const ERROR_HTML = (err) => `<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>Errore OAuth</title>
<style>body{font-family:-apple-system,sans-serif;background:#1a1b26;color:#f7768e;
  display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0}
p{font-size:14px}</style></head><body>
  <p>Errore OAuth: ${err.replace(/</g, '&lt;')}</p>
</body></html>`;

// ── Helpers browser ────────────────────────────────────────────────────────────

function openBrowser(url) {
  try {
    execSync(`open "${url}"`, { stdio: 'ignore' });
    return true;
  } catch {
    return false;
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
    // Potrebbe essere l'URL completo di redirect
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

    function finish(err, tokens) {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      try { server.close(); } catch {}
      if (err) reject(err); else resolve(tokens);
    }

    async function handleCode(code) {
      const tokens = await exchangeCode(code, pkce.verifier);
      saveTokens(tokens);
      finish(null, tokens);
    }

    const server = http.createServer(async (req, res) => {
      const url = new URL(req.url ?? '/', 'http://localhost');

      if (url.pathname !== '/auth/callback') {
        res.writeHead(404, { 'Content-Type': 'text/plain' }).end('Not found');
        return;
      }

      const returnedState = url.searchParams.get('state');
      const code          = url.searchParams.get('code');
      const oauthError    = url.searchParams.get('error');

      if (oauthError) {
        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' }).end(ERROR_HTML(oauthError));
        finish(new Error(oauthError));
        return;
      }

      if (returnedState !== pkce.state || !code) {
        res.writeHead(400, { 'Content-Type': 'text/plain' }).end('Invalid request');
        return;
      }

      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' }).end(SUCCESS_HTML);

      try { await handleCode(code); } catch (e) { finish(e); }
    });

    const timer = setTimeout(() => {
      finish(new Error('Timeout: OAuth non completato entro 10 minuti'));
    }, OAUTH_TIMEOUT_MS);

    server.listen(CALLBACK_PORT, '127.0.0.1', () => {
      console.log(`\x1b[36mOpenAI OAuth PKCE\x1b[0m`);
      console.log(`Server callback in ascolto su porta ${CALLBACK_PORT}`);
      console.log();

      if (openBrowser(authorizeUrl)) {
        console.log('Browser aperto. Completa il login su OpenAI...');
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
        const code = extractCodeFromUrl(input, pkce.state);
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
    console.error('Nessun token salvato. Esegui prima: oauth-openai.mjs login');
    process.exit(1);
  }

  console.log('Rinnovo token OpenAI...');
  const tokens = await refreshToken(stored.tokens.refresh_token);
  saveTokens(tokens);
  console.log(`Token rinnovato. Scade: ${new Date(tokens.expires_at).toLocaleString()}`);
}

// ── Comando status ─────────────────────────────────────────────────────────────
function showStatus() {
  const stored = loadTokens();
  if (!stored) {
    console.log('Nessun token OpenAI salvato.');
    console.log(`File atteso: ${AUTH_FILE}`);
    process.exit(1);
  }

  const now = Date.now();
  const expired = now > stored.expires_at;
  const remaining = expired ? 0 : Math.round((stored.expires_at - now) / 60000);

  console.log(`\x1b[36mOpenAI OAuth Status\x1b[0m`);
  console.log(`File:       ${AUTH_FILE}`);
  console.log(`Account ID: ${stored.account_id || '(sconosciuto)'}`);
  console.log(`Scadenza:   ${new Date(stored.expires_at).toLocaleString()}`);
  console.log(`Stato:      ${expired ? '\x1b[31mSCADUTO\x1b[0m' : `\x1b[32mValido\x1b[0m (${remaining} min rimanenti)`}`);

  if (expired) {
    console.log();
    console.log('Esegui: oauth-openai.mjs refresh');
  }
}

// ── Comando ensure (per uso automatico da ccproxy) ─────────────────────────────
async function ensureValid() {
  const stored = loadTokens();
  if (!stored?.tokens?.refresh_token) {
    // Nessun token: serve login interattivo
    process.exit(1);
  }

  if (Date.now() < stored.expires_at) {
    // Token ancora valido
    process.exit(0);
  }

  // Token scaduto: tenta refresh silenzioso
  try {
    const tokens = await refreshToken(stored.tokens.refresh_token);
    saveTokens(tokens);
    process.exit(0);
  } catch {
    // Refresh fallito: serve login interattivo
    process.exit(1);
  }
}

// ── Main ───────────────────────────────────────────────────────────────────────
const command = process.argv[2] ?? 'login';

switch (command) {
  case 'login':
    try {
      const tokens = await login();
      console.log();
      console.log(`\x1b[32mLogin completato!\x1b[0m`);
      console.log(`Token salvato in: ${AUTH_FILE}`);
      console.log(`Account ID: ${tokens.account_id || '(sconosciuto)'}`);
      console.log(`Scadenza:   ${new Date(tokens.expires_at).toLocaleString()}`);
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
      console.log('Potrebbe servire un nuovo login: oauth-openai.mjs login');
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
    console.log('Uso: oauth-openai.mjs <login|refresh|status|ensure>');
    process.exit(1);
}

#!/usr/bin/env node
// OAuth PKCE flow per Anthropic (Claude MAX) — standalone, zero dipendenze esterne.
// Estratto da BigBot/src/setup/oauth.ts e adattato per CLI.
//
// Uso:
//   node oauth-claude.mjs login     # Flusso OAuth (apre browser, utente incolla codice)
//   node oauth-claude.mjs refresh   # Rinnova token esistente
//   node oauth-claude.mjs status    # Mostra stato token corrente
//   node oauth-claude.mjs ensure    # Verifica/rinnova silenziosamente (per automazione)
//
// Formato output (~/.claude/.credentials.json):
//   { "claudeAiOauth": { "accessToken": "...", "refreshToken": "...", "expiresAt": <epoch_ms> } }

import { createHash, randomBytes } from 'node:crypto';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { homedir } from 'node:os';
import { execSync } from 'node:child_process';
import { createInterface } from 'node:readline';

// ── Costanti OAuth Anthropic ───────────────────────────────────────────────────
const CLIENT_ID     = '9d1c250a-e61b-44d9-88ed-5944d1962f5e';
const AUTHORIZE_URL = 'https://claude.ai/oauth/authorize';
const TOKEN_URL     = 'https://console.anthropic.com/v1/oauth/token';
const REDIRECT_URI  = 'https://console.anthropic.com/oauth/code/callback';
const SCOPES        = 'org:create_api_key user:profile user:inference';
const REFRESH_BUFFER_MS = 5 * 60 * 1000; // 5 minuti

const AUTH_DIR  = join(homedir(), '.claude');
const AUTH_FILE = join(AUTH_DIR, '.credentials.json');

// ── Utilità ────────────────────────────────────────────────────────────────────
function base64url(buf) {
  return buf.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

function generatePkce() {
  const verifier  = base64url(randomBytes(32));
  const challenge = base64url(createHash('sha256').update(verifier).digest());
  return { verifier, challenge };
}

function buildAuthorizeUrl(pkce) {
  const url = new URL(AUTHORIZE_URL);
  url.searchParams.set('code', 'true');
  url.searchParams.set('client_id', CLIENT_ID);
  url.searchParams.set('response_type', 'code');
  url.searchParams.set('redirect_uri', REDIRECT_URI);
  url.searchParams.set('scope', SCOPES);
  url.searchParams.set('code_challenge', pkce.challenge);
  url.searchParams.set('code_challenge_method', 'S256');
  url.searchParams.set('state', pkce.verifier);
  return url.toString();
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

function openBrowser(url) {
  try {
    execSync(`open "${url}"`, { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

// ── Token exchange ─────────────────────────────────────────────────────────────
async function exchangeCode(code, verifier) {
  const res = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      grant_type:    'authorization_code',
      client_id:     CLIENT_ID,
      code,
      state:         verifier,
      redirect_uri:  REDIRECT_URI,
      code_verifier: verifier,
    }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Token exchange fallito (${res.status}): ${text}`);
  }
  const data = await res.json();
  if (!data.access_token || !data.refresh_token || !data.expires_in) {
    throw new Error('Risposta token Anthropic incompleta');
  }
  return {
    accessToken:  data.access_token,
    refreshToken: data.refresh_token,
    expiresAt:    Date.now() + data.expires_in * 1000 - REFRESH_BUFFER_MS,
  };
}

async function refreshToken(currentRefreshToken) {
  const res = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      grant_type:    'refresh_token',
      client_id:     CLIENT_ID,
      refresh_token: currentRefreshToken,
    }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Token refresh fallito (${res.status}): ${text}`);
  }
  const data = await res.json();
  if (!data.access_token || !data.expires_in) {
    throw new Error('Risposta refresh Anthropic incompleta');
  }
  return {
    accessToken:  data.access_token,
    refreshToken: data.refresh_token ?? currentRefreshToken,
    expiresAt:    Date.now() + data.expires_in * 1000 - REFRESH_BUFFER_MS,
  };
}

// ── Persistenza ────────────────────────────────────────────────────────────────
// Formato compatibile con ccproxy: { "claudeAiOauth": { "accessToken": "..." } }
// Merge con contenuto esistente per non rompere altri campi di Claude Code.

function saveTokens(tokens) {
  mkdirSync(AUTH_DIR, { recursive: true });
  let existing = {};
  try {
    existing = JSON.parse(readFileSync(AUTH_FILE, 'utf-8'));
  } catch { /* file non esiste o malformato */ }

  existing.claudeAiOauth = {
    accessToken:  tokens.accessToken,
    refreshToken: tokens.refreshToken,
    expiresAt:    tokens.expiresAt,
  };

  writeFileSync(AUTH_FILE, JSON.stringify(existing, null, 2) + '\n', { mode: 0o600 });
}

function loadTokens() {
  try {
    const data = JSON.parse(readFileSync(AUTH_FILE, 'utf-8'));
    return data.claudeAiOauth ?? null;
  } catch {
    return null;
  }
}

// ── Flusso OAuth login ─────────────────────────────────────────────────────────
async function login() {
  const pkce = generatePkce();
  const authorizeUrl = buildAuthorizeUrl(pkce);

  console.log(`\x1b[35mAnthropic OAuth PKCE\x1b[0m`);
  console.log();

  // Apri il browser
  if (openBrowser(authorizeUrl)) {
    console.log('Browser aperto. Completa il login su claude.ai...');
  } else {
    console.log('Apri questo URL nel browser:');
    console.log();
    console.log(`  ${authorizeUrl}`);
  }

  console.log();
  console.log('Dopo il login, Anthropic mostrera un codice di autorizzazione.');
  console.log();

  let rawInput = await prompt('Incolla il codice qui: ');

  if (!rawInput) {
    throw new Error('Nessun codice inserito');
  }

  // Pulisci input: rimuovi frammento URL (#...), spazi, e estrai code da URL se incollato intero
  let code = rawInput.trim();
  // Se l'utente ha incollato un URL intero, estrai il parametro code
  if (code.startsWith('http')) {
    try {
      const url = new URL(code);
      code = url.searchParams.get('code') ?? code;
    } catch { /* non è un URL, usa come codice diretto */ }
  }
  // Rimuovi frammento URL (#...) che Safari può aggiungere
  code = code.split('#')[0].trim();

  if (!code) {
    throw new Error('Nessun codice valido trovato nell\'input');
  }

  console.log();
  console.log('Scambio codice per token...');

  const tokens = await exchangeCode(code, pkce.verifier);
  saveTokens(tokens);
  return tokens;
}

// ── Comando refresh ────────────────────────────────────────────────────────────
async function doRefresh() {
  const stored = loadTokens();
  if (!stored?.refreshToken) {
    console.error('Nessun token salvato. Esegui prima: oauth-claude.mjs login');
    process.exit(1);
  }

  console.log('Rinnovo token Anthropic...');
  const tokens = await refreshToken(stored.refreshToken);
  saveTokens(tokens);
  console.log(`Token rinnovato. Scade: ${new Date(tokens.expiresAt).toLocaleString()}`);
}

// ── Comando status ─────────────────────────────────────────────────────────────
function showStatus() {
  const stored = loadTokens();
  if (!stored) {
    console.log('Nessun token Anthropic salvato.');
    console.log(`File atteso: ${AUTH_FILE}`);
    process.exit(1);
  }

  const now = Date.now();
  const expired = now > stored.expiresAt;
  const remaining = expired ? 0 : Math.round((stored.expiresAt - now) / 60000);

  console.log(`\x1b[35mAnthropic OAuth Status\x1b[0m`);
  console.log(`File:     ${AUTH_FILE}`);
  console.log(`Scadenza: ${new Date(stored.expiresAt).toLocaleString()}`);
  console.log(`Stato:    ${expired ? '\x1b[31mSCADUTO\x1b[0m' : `\x1b[32mValido\x1b[0m (${remaining} min rimanenti)`}`);

  if (expired) {
    console.log();
    console.log('Esegui: oauth-claude.mjs refresh');
  }
}

// ── Comando ensure (per uso automatico) ────────────────────────────────────────
async function ensureValid() {
  const stored = loadTokens();
  if (!stored?.refreshToken) {
    process.exit(1);
  }

  if (Date.now() < stored.expiresAt) {
    process.exit(0);
  }

  try {
    const tokens = await refreshToken(stored.refreshToken);
    saveTokens(tokens);
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
      const tokens = await login();
      console.log(`\x1b[32mLogin completato!\x1b[0m`);
      console.log(`Token salvato in: ${AUTH_FILE}`);
      console.log(`Scadenza: ${new Date(tokens.expiresAt).toLocaleString()}`);
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
      console.log('Potrebbe servire un nuovo login: oauth-claude.mjs login');
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
    console.log('Uso: oauth-claude.mjs <login|refresh|status|ensure>');
    process.exit(1);
}

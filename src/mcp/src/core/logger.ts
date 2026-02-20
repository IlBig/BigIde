import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const LOG_DIR = path.join(os.homedir(), '.bigide', 'logs');
const LOG_FILE = path.join(LOG_DIR, 'mcp.log');

// Assicurati che la cartella esista (fail-safe)
try {
  fs.mkdirSync(LOG_DIR, { recursive: true });
} catch (e) {
  // Ignora errore
}

export function log(level: 'INFO' | 'WARN' | 'ERROR', message: string, meta?: any) {
  const timestamp = new Date().toISOString();
  const logEntry = `[${timestamp}] [${level}] ${message} ${meta ? JSON.stringify(meta) : ''}
`;
  
  // Scrivi su file (append)
  try {
    fs.appendFileSync(LOG_FILE, logEntry);
  } catch (e) {
    // Fallback su stderr se file system fallisce
    process.stderr.write(`[LOG FAILED] ${logEntry}`);
  }

  // Scrivi su stderr per errori critici (visibili a Claude Code via stdio se non catturati)
  if (level === 'ERROR') {
    process.stderr.write(logEntry);
  }
}

export const logger = {
  info: (msg: string, meta?: any) => log('INFO', msg, meta),
  warn: (msg: string, meta?: any) => log('WARN', msg, meta),
  error: (msg: string, meta?: any) => log('ERROR', msg, meta),
};

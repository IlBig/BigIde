#!/usr/bin/env bash
set -euo pipefail

# Ensure common paths for macOS
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

BIGIDE_REPO_ROOT="${BIGIDE_REPO_ROOT:-__BIGIDE_REPO_ROOT__}"
BIGIDE_HOME="${BIGIDE_HOME:-$HOME/.bigide}"

source "$BIGIDE_REPO_ROOT/src/shell/lib/common.sh"
source "$BIGIDE_REPO_ROOT/src/shell/lib/proxy.sh"
source "$BIGIDE_REPO_ROOT/src/shell/lib/runners.sh"

log "INFO" "Avvio Claude Code..."

# Rimuove CLAUDECODE: evita errore "nested session" se BigIDE è aperto da un terminale
# che ha già una sessione Claude attiva (es. durante sviluppo)
unset CLAUDECODE 2>/dev/null || true

if command -v claude >/dev/null 2>&1; then
  clear
  launch_claude "$@"
else
  log "ERROR" "Claude Code non trovato in PATH. Installa con: npm install -g @anthropic-ai/claude-code"
  echo "Claude Code non trovato."
  sleep 10
fi

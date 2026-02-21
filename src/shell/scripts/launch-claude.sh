#!/usr/bin/env bash
set -euo pipefail

# Inizializza l'ambiente Claude Code
# Carica nvm se presente o usa il path standard
export PATH="$PATH:/usr/local/bin:/opt/homebrew/bin"

if command -v claude >/dev/null 2>&1; then
  # Se siamo in un progetto, claude lo rileverà
  exec claude
else
  echo "Claude Code non trovato."
  echo "Installa con: npm install -g @anthropic-ai/claude-code"
  sleep 10
fi

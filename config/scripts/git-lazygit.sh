#!/usr/bin/env bash
# BigIDE — Lazygit wrapper con check installazione
# Chiamato da tmux popup (prefix + g g)
# Esc al livello root chiude lazygit (quitOnTopLevelReturn)
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if ! command -v lazygit &>/dev/null; then
  printf '\n\033[38;2;255;158;100m  lazygit non trovato.\033[0m\n'
  printf '\033[38;2;86;95;137m  Installa con: brew install lazygit\033[0m\n\n'
  read -rsn1
  exit 0
fi

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  printf '\033[38;2;255;158;100m  Non è un repository git.\033[0m\n'
  sleep 1.5
  exit 0
fi

# Config BigIDE: Esc al livello root chiude lazygit
LG_CONFIG="$HOME/.bigide/lazygit/config.yml"
if [[ ! -f "$LG_CONFIG" ]]; then
  mkdir -p "$(dirname "$LG_CONFIG")"
  printf 'quitOnTopLevelReturn: true\n' > "$LG_CONFIG"
fi

exec lazygit --use-config-dir="$(dirname "$LG_CONFIG")"

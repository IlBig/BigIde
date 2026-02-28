#!/usr/bin/env bash
# BigIDE — Lazygit wrapper con check installazione
# Chiamato da tmux popup (prefix + g g)
# Esc al livello root chiude lazygit (quitOnTopLevelReturn)
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

printf '%s [EVENT] git: lazygit opened in %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$(pwd)" >> "$HOME/.bigide/logs/bigide.log" 2>/dev/null || true

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

# Config BigIDE: personalizzazioni lazygit
LG_DIR="$HOME/.bigide/lazygit"
LG_CONFIG="$LG_DIR/config.yml"
mkdir -p "$LG_DIR"
cat > "$LG_CONFIG" << 'YML'
quitOnTopLevelReturn: true
startuppopupversion: 5
gui:
  showBottomLine: false
  showRandomTip: false
YML

exec lazygit --use-config-dir="$(dirname "$LG_CONFIG")"

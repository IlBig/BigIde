#!/usr/bin/env bash
# File tree — neo-tree (LazyVim) nel pane sinistro BigIDE
# Auto-restart: se nvim crasha o esce inaspettatamente, riparte automaticamente

PROJECT_DIR="${BIGIDE_PROJECT_PATH:-$PWD}"
cd "$PROJECT_DIR"

LAZY_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/bigide/lazy"

# Plugin check: solo alla prima installazione
if [[ ! -d "$LAZY_DIR/neo-tree.nvim" ]]; then
  echo "  [BigIDE] Prima installazione plugin LazyVim..."
  NVIM_APPNAME=bigide nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
fi

export NVIM_APPNAME=bigide

# Loop di restart: ripristina il treeview se nvim esce per qualsiasi motivo
# (crash, corruzione terminale, errore Lua, ecc.)
while true; do
  # Reset terminale prima di avviare: garantisce stato pulito ad ogni restart
  printf '\033[?25h\033[0m\033[2J\033[H'
  nvim
  # nvim è uscito — attendi brevemente poi riavvia
  sleep 0.3
done

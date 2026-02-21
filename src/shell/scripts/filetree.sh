#!/usr/bin/env bash
# File tree — neo-tree (LazyVim) nel pane sinistro BigIDE
set -euo pipefail

PROJECT_DIR="${BIGIDE_PROJECT_PATH:-$PWD}"
cd "$PROJECT_DIR"

LAZY_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/bigide/lazy"

# Se i plugin non sono ancora installati, prova sync ora
if [[ ! -d "$LAZY_DIR/neo-tree.nvim" ]]; then
  echo "  [BigIDE] Prima installazione plugin LazyVim..."
  NVIM_APPNAME=bigide nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
fi

# Lancia nvim (neo-tree si apre via autocmd VimEnter)
export NVIM_APPNAME=bigide
exec nvim

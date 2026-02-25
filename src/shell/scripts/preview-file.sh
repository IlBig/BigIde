#!/usr/bin/env bash
# Apre un file in preview read-only dentro un tmux popup centrato su Ghostty
# ↑/↓ cambia file | Enter: leggi | q / Esc chiudono il popup
set -euo pipefail

FILEPATH="$1"
NAV_SCRIPT="$HOME/.bigide/scripts/preview-nav.lua"

# Pulisci file transizione precedenti
rm -f /tmp/bigide-preview-next

tmux display-popup \
  -E \
  -w "82%" \
  -h "82%" \
  -x "C" \
  -y "C" \
  "nvim -u NORC --noplugin -R \
    -c 'set number termguicolors cursorline signcolumn=no background=dark noswapfile' \
    -c 'syntax on' \
    -c 'silent! colorscheme habamax' \
    -c 'luafile $NAV_SCRIPT' \
    $(printf '%q' "$FILEPATH")"

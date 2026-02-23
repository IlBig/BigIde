#!/usr/bin/env bash
# BigIDE — Preview immagini ad alta qualità in tmux popup centrato
# Usa nvim -u init-minimale + image.nvim (Kitty protocol), NO LazyVim/neo-tree

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

FILEPATH="$1"
INIT="$HOME/.bigide/scripts/nvim-image-init.lua"

tmux display-popup \
  -E \
  -w "90%" \
  -h "90%" \
  -x "C" \
  -y "C" \
  "nvim -u $(printf '%q' "$INIT") $(printf '%q' "$FILEPATH")"

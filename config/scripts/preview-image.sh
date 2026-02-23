#!/usr/bin/env bash
# BigIDE — Preview immagini ad alta qualità in tmux popup centrato
# Usa neovim + image.nvim (Kitty Graphics Protocol) per qualità nativa
# q / Esc per chiudere

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

FILEPATH="$1"

tmux display-popup \
  -E \
  -w "90%" \
  -h "90%" \
  -x "C" \
  -y "C" \
  "NVIM_APPNAME=bigide nvim $(printf '%q' "$FILEPATH")"

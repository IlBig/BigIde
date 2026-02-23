#!/usr/bin/env bash
# BigIDE — Viewer immagini ad alta qualità (eseguito dentro Ghostty o popup tmux)
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
clear

IMG="$1"

# timg: Kitty → Sixel → quarter blocks → halfblock (cascata automatica)
if command -v timg &>/dev/null; then
  timg -pk -C "$IMG" 2>/dev/null || \
  timg -ps -C "$IMG" 2>/dev/null || \
  timg -pq -C "$IMG" 2>/dev/null || \
  timg -C "$IMG" 2>/dev/null
elif command -v chafa &>/dev/null; then
  chafa --format=kitty "$IMG" 2>/dev/null || \
  chafa "$IMG" 2>/dev/null
fi

printf '\n  %s  —  premi un tasto\n' "$(basename "$IMG")"
read -rsn1

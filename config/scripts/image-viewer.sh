#!/usr/bin/env bash
# BigIDE — Viewer immagini (popup tmux, solo rendering text-based)
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
clear

IMG="$1"

# Solo quarter blocks / halfblocks — sicuri in tmux popup, niente escape grafici
if command -v timg &>/dev/null; then
  timg -pq -C "$IMG" 2>/dev/null || \
  timg -C "$IMG" 2>/dev/null
elif command -v chafa &>/dev/null; then
  chafa "$IMG" 2>/dev/null
fi

printf '\n  %s  —  premi un tasto\n' "$(basename "$IMG")"
read -rsn1

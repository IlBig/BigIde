#!/usr/bin/env bash
# BigIDE — Preview immagini ad alta qualità
# Ghostty nativo (Kitty graphics protocol) → fallback popup tmux (halfblock)

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

FILEPATH="$1"
[ ! -f "$FILEPATH" ] && exit 1

VIEWER="$HOME/.bigide/scripts/image-viewer.sh"

# Ghostty nativo = qualità piena (Kitty graphics protocol)
if command -v ghostty &>/dev/null; then
  ghostty --fullscreen=true -e "$VIEWER" "$FILEPATH"
else
  # Fallback: popup tmux con blocchi Unicode (qualità minore)
  tmux display-popup \
    -E \
    -w "90%" \
    -h "90%" \
    -x "C" \
    -y "C" \
    "$VIEWER $(printf '%q' "$FILEPATH")"
fi

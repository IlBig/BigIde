#!/usr/bin/env bash
# BigIDE — Preview video via NSPanel overlay con AVPlayerView (sopra fullscreen)
# Foreground: on_exit di neovim scatta alla chiusura reale del viewer

FILEPATH="$1"
[ ! -f "$FILEPATH" ] && exit 1

# Risolvi percorso assoluto
[[ "$FILEPATH" != /* ]] && FILEPATH="$(cd "$(dirname "$FILEPATH")" && pwd)/$(basename "$FILEPATH")"

# Chiudi eventuale istanza precedente e pulisci file transizione
pkill -x bigide-vidview 2>/dev/null
rm -f /tmp/bigide-vidview-next /tmp/bigide-vidview-last

exec "$HOME/.bigide/tools/bigide-vidview" "$FILEPATH"

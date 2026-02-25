#!/usr/bin/env bash
# BigIDE — Preview documenti via NSPanel overlay con QLPreviewView (sopra fullscreen)
# Foreground: on_exit di neovim scatta alla chiusura reale del viewer

FILEPATH="$1"
[ ! -f "$FILEPATH" ] && exit 1

# Risolvi percorso assoluto
[[ "$FILEPATH" != /* ]] && FILEPATH="$(cd "$(dirname "$FILEPATH")" && pwd)/$(basename "$FILEPATH")"

# Chiudi eventuale istanza precedente e pulisci file transizione
pkill -x bigide-docview 2>/dev/null
rm -f /tmp/bigide-docview-next /tmp/bigide-docview-last

exec "$HOME/.bigide/tools/bigide-docview" "$FILEPATH"

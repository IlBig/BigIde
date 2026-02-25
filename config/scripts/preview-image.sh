#!/usr/bin/env bash
# BigIDE — Preview immagini via NSPanel overlay (sopra fullscreen)
# Foreground: on_exit di neovim scatta alla chiusura reale del viewer

FILEPATH="$1"
[ ! -f "$FILEPATH" ] && exit 1

# Risolvi percorso assoluto
[[ "$FILEPATH" != /* ]] && FILEPATH="$(cd "$(dirname "$FILEPATH")" && pwd)/$(basename "$FILEPATH")"

# Chiudi eventuale istanza precedente e pulisci file transizione
pkill -x bigide-imgview 2>/dev/null
rm -f /tmp/bigide-imgview-next /tmp/bigide-imgview-last

exec "$HOME/.bigide/tools/bigide-imgview" "$FILEPATH"

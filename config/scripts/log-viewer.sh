#!/usr/bin/env bash
# BigIDE — Log Viewer per il pannello logs
set -euo pipefail

BIGIDE_LOG="$HOME/.bigide/logs/bigide.log"

# Colori Tokyo Night
_DIM=$'\033[38;2;86;95;137m'
_CYAN=$'\033[38;2;125;207;255m'
_R=$'\033[0m'

# Crea file log se non esiste
mkdir -p "$(dirname "$BIGIDE_LOG")"
touch "$BIGIDE_LOG"

# Pulisci schermo completamente
clear

printf "${_CYAN}BigIDE Logs${_R}\n"
printf "${_DIM}────────────────────────────────────${_R}\n\n"

exec tail -n 20 -f "$BIGIDE_LOG" 2>/dev/null

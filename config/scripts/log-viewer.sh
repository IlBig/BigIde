#!/usr/bin/env bash
# BigIDE — Log Viewer per il pannello logs
# Mostra in tempo reale: log BigIDE + log ccproxy/litellm
set -euo pipefail

BIGIDE_LOG="$HOME/.bigide/logs/bigide.log"
CCPROXY_LOG="$HOME/.ccproxy/proxy.log"

# Colori Tokyo Night
_DIM=$'\033[38;2;86;95;137m'
_CYAN=$'\033[38;2;125;207;255m'
_R=$'\033[0m'

# Crea file log se non esistono
mkdir -p "$(dirname "$BIGIDE_LOG")" "$(dirname "$CCPROXY_LOG")"
touch "$BIGIDE_LOG" "$CCPROXY_LOG"

# Pulisci schermo completamente
clear

printf "${_CYAN}BigIDE Logs${_R}  ${_DIM}(bigide + ccproxy)${_R}\n"
printf "${_DIM}────────────────────────────────────${_R}\n\n"

# tail -f -q: quiet mode (no "==> filename <==" headers)
exec tail -n 20 -f -q "$BIGIDE_LOG" "$CCPROXY_LOG" 2>/dev/null

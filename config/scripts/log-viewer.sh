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

echo "${_CYAN}BigIDE Logs${_R}  ${_DIM}(bigide + ccproxy)${_R}"
echo "${_DIM}────────────────────────────────────${_R}"
echo

# tail -f su entrambi i file, merged
exec tail -f "$BIGIDE_LOG" "$CCPROXY_LOG" 2>/dev/null

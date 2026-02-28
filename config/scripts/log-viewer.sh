#!/usr/bin/env bash
# BigIDE — Log Viewer per il pannello logs
set -euo pipefail

BIGIDE_LOG="$HOME/.bigide/logs/bigide.log"

# Colori Tokyo Night
_DIM=$'\033[38;2;86;95;137m'
_CYAN=$'\033[38;2;125;207;255m'
_R=$'\033[0m'

mkdir -p "$(dirname "$BIGIDE_LOG")"
touch "$BIGIDE_LOG"

clear

printf "${_CYAN}BigIDE Logs${_R}  ${_DIM}(KEY=viola INFO=cyan EVENT=verde PANE=blu WARN=arancio ERROR=rosso)${_R}\n"
printf "${_DIM}────────────────────────────────────────────────────────────${_R}\n\n"

tail -n 100 -f "$BIGIDE_LOG" 2>/dev/null | awk '
  /\[KEY\]/   { printf "\033[38;2;187;154;247m%s\033[0m\n", $0; fflush(); next }
  /\[ERROR\]/ { printf "\033[38;2;247;118;142m%s\033[0m\n", $0; fflush(); next }
  /\[WARN\]/  { printf "\033[38;2;255;158;100m%s\033[0m\n", $0; fflush(); next }
  /\[EVENT\]/ { printf "\033[38;2;158;206;106m%s\033[0m\n", $0; fflush(); next }
  /\[PANE\]/  { printf "\033[38;2;122;162;247m%s\033[0m\n", $0; fflush(); next }
  /\[HOOK\]/  { printf "\033[38;2;86;95;137m%s\033[0m\n",   $0; fflush(); next }
  /\[INFO\]/  { printf "\033[38;2;125;207;255m%s\033[0m\n", $0; fflush(); next }
             { printf "\033[38;2;192;202;245m%s\033[0m\n", $0; fflush() }
'

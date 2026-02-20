#!/usr/bin/env bash
set -euo pipefail

GITHUB="https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor"

# Se claude-monitor è installato, usalo direttamente
for cmd in claude-monitor ccm cmonitor ccmonitor; do
  if command -v "$cmd" >/dev/null 2>&1; then
    exec "$cmd" --plan max5 --theme dark --refresh-rate 10
  fi
done

# Fallback: istruzioni installazione
CYAN='\033[36;1m'
YELLOW='\033[33;1m'
GREEN='\033[32;1m'
DIM='\033[2m'
NC='\033[0m'

while true; do
  clear
  printf "${CYAN}  CLAUDE USAGE${NC}\n"
  printf "\n"
  printf "  Installa il monitor:\n"
  printf "\n"
  printf "${YELLOW}  uv tool install claude-monitor${NC}\n"
  printf "\n"
  printf "${DIM}  %s${NC}\n" "$GITHUB"
  sleep 30
done

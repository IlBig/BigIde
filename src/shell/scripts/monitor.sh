#!/usr/bin/env bash
set -euo pipefail

# Se claude-monitor è installato, usalo
if command -v claude-monitor >/dev/null 2>&1; then
  exec claude-monitor --plan max5 --theme dark --refresh-rate 10
fi

# Colori
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Fallback: monitor compatto (ottimizzato per pane piccoli)
while true; do
  clear
  echo -e "${CYAN}  BIGIDE MONITOR  ${NC}${YELLOW}$(date '+%H:%M:%S')${NC}"
  echo

  # CPU
  if [[ "$(uname)" == "Darwin" ]]; then
    cpu=$(ps -A -o %cpu | awk '{s+=$1} END {printf "%.1f%%", s}')
  else
    cpu=$(top -bn1 | grep "Cpu(s)" | awk '{printf "%.1f%%", $2+$4}')
  fi
  echo -e " ${GREEN}CPU${NC}  $cpu"

  # RAM
  if [[ "$(uname)" == "Darwin" ]]; then
    vm_stat | awk '
      /Pages free/                   {free=$3}
      /Pages active/                 {active=$3}
      /Pages wired down/             {wired=$3}
      /Pages occupied by compressor/ {comp=$3}
      END {
        gsub(/\./,"",free); gsub(/\./,"",active); gsub(/\./,"",wired); gsub(/\./,"",comp)
        used=(active+wired+comp)*4096/1024/1024/1024
        printf " \033[0;32mRAM\033[0m  %.1f GB\n", used
      }'
  else
    free -h | awk '/Mem:/ {printf " \033[0;32mRAM\033[0m  %s / %s\n", $3, $2}'
  fi

  sleep 5
done

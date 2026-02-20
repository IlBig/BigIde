#!/usr/bin/env bash
set -euo pipefail

repair_runtime() {
  log "INFO" "Repair runtime avviato"
  init_runtime
  mkdir -p "$BIGIDE_HOME/logs"
  touch "$BIGIDE_HOME/logs/mcp.log" "$BIGIDE_HOME/logs/bigide.log"
  log "INFO" "Repair runtime completato"
}

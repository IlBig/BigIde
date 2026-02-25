#!/usr/bin/env bash
set -euo pipefail

update_bigide() {
  log "INFO" "Update locale: nessun registry configurato, eseguo verifica baseline"
  init_runtime
  log "INFO" "Update completato (baseline config sincronizzata senza overwrite)"
}

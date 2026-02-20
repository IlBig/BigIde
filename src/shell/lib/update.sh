#!/usr/bin/env bash
set -euo pipefail

update_bigide() {
  log "INFO" "Update locale: nessun registry configurato, eseguo verifica baseline"
  init_runtime

  if jq -e '.ccproxy.transparent == true and .ccproxy.mode != "disabled"' "$BIGIDE_HOME/config.json" >/dev/null 2>&1; then
    ensure_ccproxy || log "WARN" "ccproxy non installabile automaticamente in questo ambiente"
  fi

  log "INFO" "Update completato (baseline config sincronizzata senza overwrite)"
}

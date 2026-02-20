#!/usr/bin/env bash
set -euo pipefail

required_commands() {
  cat <<'CMDS'
tmux
jq
git
yazi
claude
CMDS
}

optional_commands() {
  cat <<'CMDS'
ccproxy
CMDS
}

check_dependencies() {
  local missing=0

  while IFS= read -r cmd; do
    [[ -n "$cmd" ]] || continue
    if ! command -v "$cmd" >/dev/null 2>&1; then
      log "WARN" "Dipendenza mancante: $cmd"
      missing=1
    fi
  done < <(required_commands)

  while IFS= read -r cmd; do
    [[ -n "$cmd" ]] || continue
    if ! command -v "$cmd" >/dev/null 2>&1; then
      log "INFO" "Dipendenza opzionale assente: $cmd (verrà gestita automaticamente se richiesto)"
    fi
  done < <(optional_commands)

  if [[ "$missing" -eq 1 ]]; then
    die "Dipendenze mancanti. Installa i comandi segnalati e riesegui."
  fi
}

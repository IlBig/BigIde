#!/usr/bin/env bash
set -euo pipefail

BIGIDE_HOME="${BIGIDE_HOME:-$HOME/.bigide}"
BIGIDE_REPO_ROOT="${BIGIDE_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"

log() {
  local level="$1"; shift
  mkdir -p "$BIGIDE_HOME/logs"
  printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" | tee -a "$BIGIDE_HOME/logs/bigide.log"
}

# bide_log: scrivi solo su file, senza stdout (evita doppia scrittura quando stdout è rediretto)
bide_log() {
  local level="$1"; shift
  printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" >> "$BIGIDE_HOME/logs/bigide.log"
}

die() {
  log "ERROR" "$*"
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Dipendenza mancante: $1"
}

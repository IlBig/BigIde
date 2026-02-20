#!/usr/bin/env bash
# File tree explorer — broot con tema VSCode dark
set -euo pipefail

BROOT_CONF="$HOME/.bigide/broot/conf.toml"
PROJECT_DIR="${BIGIDE_PROJECT_PATH:-$PWD}"

if command -v broot >/dev/null 2>&1; then
  cd "$PROJECT_DIR"
  exec broot --conf "$BROOT_CONF" --color yes
else
  # Fallback: yazi se broot non installato
  echo "[WARN] broot non trovato. Installa con: brew install broot"
  echo "       oppure aggiungi 'broot' alle dipendenze in setup.sh"
  sleep 2
  YAZI_CONFIG_HOME="$HOME/.bigide/yazi" exec yazi "$PROJECT_DIR" 2>/dev/null \
    || exec ls -la "$PROJECT_DIR"
fi

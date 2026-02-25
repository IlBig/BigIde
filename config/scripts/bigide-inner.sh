#!/usr/bin/env bash
# BigIDE inner launcher — eseguito da Ghostty all'avvio
# Viene installato in ~/.bigide/scripts/ con sostituzione __BIGIDE_REPO_ROOT__
set -euo pipefail

BIGIDE_REPO_ROOT="__BIGIDE_REPO_ROOT__"
export BIGIDE_REPO_ROOT
export BIGIDE_LAUNCHED_FROM_APP=1

# Forza ARM64 nativo se siamo sotto Rosetta 2 (x86_64 emulato)
if [[ "$(uname -m)" != "arm64" ]]; then
  exec arch -arm64 /bin/zsh -l -c "BIGIDE_REPO_ROOT='$BIGIDE_REPO_ROOT' BIGIDE_LAUNCHED_FROM_APP=1 exec '$BIGIDE_REPO_ROOT/bin/bigide' $*"
fi

exec "$BIGIDE_REPO_ROOT/bin/bigide" "$@"

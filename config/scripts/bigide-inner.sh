#!/usr/bin/env bash
# BigIDE inner launcher — eseguito da Ghostty all'avvio
# Viene installato in ~/.bigide/scripts/ con sostituzione __BIGIDE_REPO_ROOT__
set -euo pipefail

BIGIDE_REPO_ROOT="__BIGIDE_REPO_ROOT__"
export BIGIDE_REPO_ROOT

exec "$BIGIDE_REPO_ROOT/bin/bigide" "$@"

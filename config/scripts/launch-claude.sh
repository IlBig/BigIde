#!/usr/bin/env bash
set -euo pipefail

# Ensure common paths for macOS
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

BIGIDE_REPO_ROOT="${BIGIDE_REPO_ROOT:-__BIGIDE_REPO_ROOT__}"
BIGIDE_HOME="${BIGIDE_HOME:-$HOME/.bigide}"

source "$BIGIDE_REPO_ROOT/src/shell/lib/common.sh"
source "$BIGIDE_REPO_ROOT/src/shell/lib/runners.sh"

log "INFO" "Avvio provider AI..."

clear
launch_claude "$@"

#!/usr/bin/env bash
set -euo pipefail

BIGIDE_REPO_ROOT="${BIGIDE_REPO_ROOT:-__BIGIDE_REPO_ROOT__}"
BIGIDE_HOME="${BIGIDE_HOME:-$HOME/.bigide}"

source "$BIGIDE_REPO_ROOT/src/shell/lib/common.sh"
source "$BIGIDE_REPO_ROOT/src/shell/lib/ccproxy.sh"

launch_claude_with_proxy

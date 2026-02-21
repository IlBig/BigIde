#!/usr/bin/env bash
# File tree explorer — neo-tree (LazyVim) nel pane sinistro BigIDE
set -euo pipefail

PROJECT_DIR="${BIGIDE_PROJECT_PATH:-$PWD}"

cd "$PROJECT_DIR"
exec NVIM_APPNAME=bigide nvim 2>/dev/null

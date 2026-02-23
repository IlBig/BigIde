#!/usr/bin/env bash
# Apre un file in preview read-only dentro un tmux popup centrato su Ghostty
# q / Esc chiudono il popup
set -euo pipefail

FILEPATH="$1"

tmux display-popup \
  -E \
  -w "82%" \
  -h "82%" \
  -x "C" \
  -y "C" \
  "BIGIDE_PREVIEW=1 NVIM_APPNAME=bigide nvim -R $(printf '%q' "$FILEPATH")"

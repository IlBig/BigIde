#!/usr/bin/env bash
set -euo pipefail

session_name_for_path() {
  local project_path="$1"
  local base
  base="$(basename "$project_path")"
  echo "bigide-${base//[^[:alnum:]]/-}"
}

session_exists() {
  local session_name="$1"
  tmux has-session -t "$session_name" 2>/dev/null
}

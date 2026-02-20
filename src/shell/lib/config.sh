#!/usr/bin/env bash
set -euo pipefail

read_config() {
  local key="$1"
  jq -r "$key" "$BIGIDE_HOME/config.json"
}

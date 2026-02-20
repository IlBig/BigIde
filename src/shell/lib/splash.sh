#!/usr/bin/env bash
set -euo pipefail

show_splash() {
  local step="$1"
  local pct="$2"
  printf '\r\033[36mBigIDE\033[0m [%3s%%] %s' "$pct" "$step"
}

end_splash() {
  printf '\n'
}

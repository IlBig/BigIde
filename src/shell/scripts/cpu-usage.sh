#!/usr/bin/env bash
# CPU usage macOS — user+sys via top
top -l 1 -s 0 -n 0 2>/dev/null \
  | awk '/CPU usage/ {
      match($3, /[0-9.]+/); u = substr($3, RSTART, RLENGTH) + 0
      match($5, /[0-9.]+/); s = substr($5, RSTART, RLENGTH) + 0
      printf "%.0f%%", u + s
    }' 2>/dev/null \
  || echo "?%"

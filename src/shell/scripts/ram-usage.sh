#!/usr/bin/env bash
# RAM usata macOS — active+wired+compressed via vm_stat
vm_stat 2>/dev/null | awk '
  /Pages active/                  { a = $NF + 0 }
  /Pages wired down/              { w = $NF + 0 }
  /Pages occupied by compressor/  { c = $NF + 0 }
  END {
    gb = (a + w + c) * 4096 / 1073741824
    if (gb > 0) printf "%.1fG", gb
    else        printf "?G"
  }
' 2>/dev/null || echo "?G"

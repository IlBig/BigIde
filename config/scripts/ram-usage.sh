#!/usr/bin/env bash
# RAM usata macOS — legge direttamente da top (come Activity Monitor)
# Usa vm.pagesize reale (16384 su Apple Silicon, non hardcoded 4096)
top -l 1 -s 0 -n 0 2>/dev/null \
  | awk '/PhysMem/ { print $2 }' \
  || echo "?G"

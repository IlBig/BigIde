#!/usr/bin/env bash
# RAM occupata macOS — percentuale (usata / totale)
# Legge da top: "PhysMem: 15G used (...), 1119M unused."
top -l 1 -s 0 -n 0 2>/dev/null \
  | awk '
    function mb(s,   n) {
      n = s + 0
      if (index(s,"G")) return n * 1024
      if (index(s,"M")) return n
      if (index(s,"K")) return int(n / 1024)
      return int(n / 1048576)
    }
    /PhysMem/ {
      total = mb($2) + mb($6)
      if (total > 0) printf "%d%%\n", mb($2) * 100 / total
      else            print "?%"
    }' \
  || echo "?%"

#!/usr/bin/env bash
# Git bar: status git con colori ANSI per pane tmux
set -euo pipefail

CYAN='\033[36;1m'
GREEN='\033[32;1m'
BLUE='\033[34;1m'
MAGENTA='\033[35;1m'
YELLOW='\033[33;1m'
NC='\033[0m'

while true; do
  clear
  if git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git symbolic-ref --short HEAD 2>/dev/null \
             || git rev-parse --short HEAD 2>/dev/null \
             || echo "detached")
    [ "${#branch}" -gt 30 ] && branch="${branch:0:27}…"

    staged=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    modified=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

    st=""
    [ "$staged"    -gt 0 ] && st="${st}${GREEN}● ${staged}${NC} "
    [ "$modified"  -gt 0 ] && st="${st}${BLUE}✚ ${modified}${NC} "
    [ "$untracked" -gt 0 ] && st="${st}${MAGENTA}… ${untracked}${NC}"
    [ -z "$st" ] && st="${GREEN}✔${NC}"

    # ahead/behind
    remote=$(git rev-parse --abbrev-ref "@{u}" 2>/dev/null || true)
    if [ -n "$remote" ]; then
      ahead=$(git rev-list --count "@{u}..HEAD" 2>/dev/null || echo 0)
      behind=$(git rev-list --count "HEAD..@{u}" 2>/dev/null || echo 0)
      [ "$ahead"  -gt 0 ] && st="${st} ${YELLOW}↑${ahead}${NC}"
      [ "$behind" -gt 0 ] && st="${st} ${YELLOW}↓${behind}${NC}"
    fi

    printf "${CYAN}  %s${NC}  %b\n" "$branch" "$st"
  else
    printf "${NC}  (no git)\n"
  fi

  sleep 5
done

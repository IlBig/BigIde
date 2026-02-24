#!/usr/bin/env bash
# BigIDE — Git log con graph stilizzato
# Chiamato da tmux popup (prefix + g l)
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

B=$'\033[38;2;122;162;247m'
D=$'\033[38;2;86;95;137m'
R=$'\033[0m'

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  printf '\033[38;2;255;158;100m  Non è un repository git.\033[0m\n'
  sleep 1.5
  exit 0
fi

printf "\n${B}  Git Log${R}\n"
printf "${D}  ──────────────────────────────${R}\n\n"

git log --oneline --graph --decorate --color=always -n 30 2>&1 | less -R -F -X

printf "\n"

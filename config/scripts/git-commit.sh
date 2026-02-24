#!/usr/bin/env bash
# BigIDE — Git add + commit con prompt
# Chiamato da tmux popup (prefix + g c)
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Colori
G=$'\033[38;2;158;206;106m'
O=$'\033[38;2;255;158;100m'
B=$'\033[38;2;122;162;247m'
W=$'\033[38;2;192;202;245m'
D=$'\033[38;2;86;95;137m'
R=$'\033[0m'

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  printf "${O}  Non è un repository git.${R}\n"
  sleep 1.5
  exit 0
fi

# Mostra stato corrente
printf "\n${B}  Modifiche:${R}\n\n"
git status --short 2>/dev/null

# Niente da committare?
if git diff --quiet HEAD 2>/dev/null && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
  printf "\n${D}  Niente da committare, working tree pulito.${R}\n"
  sleep 1.5
  exit 0
fi

printf "\n"
# Prompt messaggio
printf "${B}"
read -r -p "  Commit msg: " msg
printf "${R}"

if [[ -z "$msg" ]]; then
  printf "${D}  Annullato.${R}\n"
  sleep 1
  exit 0
fi

# Stage + commit
git add -A
if git commit -m "$msg" 2>&1; then
  printf "\n${G}  ✔ Commit creato.${R}\n"
else
  printf "\n${O}  ✘ Commit fallito.${R}\n"
fi

sleep 1.5

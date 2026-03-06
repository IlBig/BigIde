#!/usr/bin/env bash
# BigIDE — barra git (1 riga fissa in fondo)
# Output: \r\033[K per sovrascrivere sempre la stessa riga

PROJECT_DIR="${1:-$PWD}"

printf '\033[?25l\033[2J\033[H'   # nasconde cursore + pulisce il prompt zsh iniziale
stty -echo 2>/dev/null || true

build_git() {
  if ! git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    printf '\033[90m nessun repo git\033[0m'
    return
  fi

  local branch ahead behind staged modified untracked stash
  branch=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || \
           git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo "?")

  ahead=0; behind=0
  if git -C "$PROJECT_DIR" rev-parse '@{upstream}' &>/dev/null 2>&1; then
    ahead=$(git  -C "$PROJECT_DIR" rev-list --count '@{upstream}..HEAD' 2>/dev/null || echo 0)
    behind=$(git -C "$PROJECT_DIR" rev-list --count 'HEAD..@{upstream}' 2>/dev/null || echo 0)
  fi

  staged=$(git    -C "$PROJECT_DIR" diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
  modified=$(git  -C "$PROJECT_DIR" diff --name-only           2>/dev/null | wc -l | tr -d ' ')
  untracked=$(git -C "$PROJECT_DIR" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
  stash=$(git     -C "$PROJECT_DIR" stash list 2>/dev/null | wc -l | tr -d ' ')

  local out=" \033[36;1m⎇ ${branch}\033[0m"
  [[ "$ahead"     -gt 0 ]] && out+="   \033[33;1m↑${ahead} da pushare\033[0m"
  [[ "$behind"    -gt 0 ]] && out+="   \033[31;1m↓${behind}\033[0m"
  [[ "$staged"    -gt 0 ]] && out+="   \033[32;1m● ${staged} staged\033[0m"
  [[ "$modified"  -gt 0 ]] && out+="   \033[34;1m✚ ${modified} modificati\033[0m"
  [[ "$untracked" -gt 0 ]] && out+="   \033[35;1m? ${untracked} nuovi\033[0m"
  [[ "$stash"     -gt 0 ]] && out+="   \033[36m⚑ ${stash} stash\033[0m"
  [[ "$staged" -eq 0 && "$modified" -eq 0 && "$untracked" -eq 0 && \
     "$ahead"  -eq 0 && "$behind"  -eq 0 ]] && out+="   \033[32m✔ pulito\033[0m"

  printf '%b' "$out"
}

while true; do
  # \r = inizio riga, \033[K = cancella fino a fine riga, poi stampa
  printf '\r\033[K'
  build_git
  sleep 5
done

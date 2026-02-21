#!/usr/bin/env bash
# BigIDE — barra git in fondo (1 riga fissa) — tema Tokyo Night

PROJECT_DIR="${1:-$PWD}"

# Tokyo Night RGB
TN_CYAN='\033[38;2;125;207;255m'    # #7dcfff — branch
TN_BLUE='\033[38;2;122;162;247m'    # #7aa2f7 — modificati
TN_GREEN='\033[38;2;158;206;106m'   # #9ece6a — staged / pulito
TN_YELLOW='\033[38;2;224;175;104m'  # #e0af68 — da pushare
TN_RED='\033[38;2;247;118;142m'     # #f7768e — da pullare
TN_PURPLE='\033[38;2;187;154;247m'  # #bb9af7 — untracked
TN_COMMENT='\033[38;2;86;95;137m'   # #565f89 — testo secondario
TN_BG='\033[48;2;26;27;38m'         # #1a1b26 — sfondo Tokyo Night
RESET='\033[0m'

printf '\033[?25l'         # nasconde cursore
stty -echo 2>/dev/null || true

build_git() {
  if ! git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    printf "${TN_BG}${TN_COMMENT} nessun repo git${RESET}"
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

  local out="${TN_BG}"
  out+=" ${TN_CYAN}⎇ ${branch}${RESET}${TN_BG}"
  [[ "$ahead"     -gt 0 ]] && out+="${TN_COMMENT}   ${TN_YELLOW}↑${ahead} da pushare${RESET}${TN_BG}"
  [[ "$behind"    -gt 0 ]] && out+="${TN_COMMENT}   ${TN_RED}↓${behind} da pullare${RESET}${TN_BG}"
  [[ "$staged"    -gt 0 ]] && out+="${TN_COMMENT}   ${TN_GREEN}● ${staged} staged${RESET}${TN_BG}"
  [[ "$modified"  -gt 0 ]] && out+="${TN_COMMENT}   ${TN_BLUE}✚ ${modified} modificati${RESET}${TN_BG}"
  [[ "$untracked" -gt 0 ]] && out+="${TN_COMMENT}   ${TN_PURPLE}? ${untracked} nuovi${RESET}${TN_BG}"
  [[ "$stash"     -gt 0 ]] && out+="${TN_COMMENT}   ${TN_CYAN}⚑ ${stash} stash${RESET}${TN_BG}"
  [[ "$staged" -eq 0 && "$modified" -eq 0 && "$untracked" -eq 0 && \
     "$ahead"  -eq 0 && "$behind"  -eq 0 ]] && \
    out+="${TN_COMMENT}   ${TN_GREEN}✔ pulito${RESET}${TN_BG}"
  out+="${RESET}"

  printf '%b' "$out"
}

while true; do
  printf '\r\033[K'
  build_git
  sleep 5
done

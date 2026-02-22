#!/usr/bin/env bash
# BigIDE — Perplexity interactive REPL
# Tema: Tokyo Night Storm — stile dialog LazyVim

TOKENS_FILE="$HOME/.bigide/perplexity/tokens.env"
HISTORY_FILE="$HOME/.bigide/perplexity/history"
CLIENT_PY="$HOME/.bigide/scripts/perplexity/client.py"

# ── TOKYO NIGHT STORM ─────────────────────────────────────────────
TN_BLUE='\033[38;2;122;162;247m'    # #7aa2f7
TN_GREEN='\033[38;2;158;206;106m'   # #9ece6a
TN_YELLOW='\033[38;2;224;175;104m'  # #e0af68
TN_FG='\033[38;2;192;202;245m'      # #c0caf5
TN_COMMENT='\033[38;2;86;95;137m'   # #565f89
TN_DARK='\033[38;2;65;72;104m'      # #414868
TN_BOLD='\033[1m'
TN_RESET='\033[0m'

INDENT=" "   # padding sinistro uniforme (stile dialog)

# ── LAYOUT ────────────────────────────────────────────────────────

_cols() { tput cols 2>/dev/null || echo 80; }

_draw_header() {
  local cols; cols=$(_cols)
  local inner=$((cols - 2))
  # Titolo visibile (senza ANSI): " ● Perplexity "
  local title=" ● Perplexity "
  local tlen=${#title}
  local ldashes=$(( (inner - tlen) / 2 ))
  local rdashes=$(( inner - tlen - ldashes ))
  local ld rd
  ld=$(printf '─%.0s' $(seq 1 $ldashes))
  rd=$(printf '─%.0s' $(seq 1 $rdashes))
  echo -e "${TN_DARK}╭${ld}${TN_RESET}${TN_BLUE}${TN_BOLD}${title}${TN_RESET}${TN_DARK}${rd}╮${TN_RESET}"
}

_draw_separator() {
  local cols; cols=$(_cols)
  local sep
  sep=$(printf '─%.0s' $(seq 1 $((cols - 1))))
  echo -e "${TN_DARK}${INDENT}${sep}${TN_RESET}"
}

# ── SPINNER ───────────────────────────────────────────────────────

SPINNER_PID=""

_start_spinner() {
  tput civis 2>/dev/null
  (
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    while true; do
      printf "\r${INDENT}${TN_BLUE}${TN_BOLD}${frames[$((i % 10))]}${TN_RESET}" >&2
      sleep 0.08
      ((i++))
    done
  ) &
  SPINNER_PID=$!
}

_stop_spinner() {
  [[ -n "$SPINNER_PID" ]] && kill "$SPINNER_PID" 2>/dev/null && wait "$SPINNER_PID" 2>/dev/null
  printf "\r\033[K"
  tput cnorm 2>/dev/null
  SPINNER_PID=""
}

trap '_stop_spinner; echo -e "\n${TN_COMMENT}Perplexity chiuso.${TN_RESET}"' EXIT INT TERM

# ── INIZIALIZZAZIONE ──────────────────────────────────────────────

[[ -f "$TOKENS_FILE" ]] && source "$TOKENS_FILE"

_check_tokens() {
  [[ -n "${PERPLEXITY_SESSION_TOKEN:-}" ]] && return 0
  echo -e "${TN_YELLOW}${INDENT}⚠  Token non configurato.${TN_RESET}"
  echo -e "${TN_COMMENT}${INDENT}   perplexity.ai → F12 → Cookies → __Secure-next-auth.session-token${TN_RESET}"
  echo -e "${TN_COMMENT}${INDENT}   Incolla in: ~/.bigide/perplexity/tokens.env${TN_RESET}"
  return 1
}

_ensure_deps() {
  python3 -c "import tls_client" 2>/dev/null && return 0
  pip3 install -q tls-client typing_extensions 2>/dev/null || {
    echo -e "${TN_YELLOW}${INDENT}⚠  pip3 install tls-client fallito${TN_RESET}"
    return 1
  }
}

# ── QUERY + OUTPUT ────────────────────────────────────────────────

_query() {
  PERPLEXITY_SESSION_TOKEN="$PERPLEXITY_SESSION_TOKEN" \
    python3 "$CLIENT_PY" "$1"
}

_print_result() {
  if command -v glow >/dev/null 2>&1; then
    echo "$1" | glow --width $(( $(_cols) - 4 )) - 2>/dev/null || echo -e "${TN_FG}$1${TN_RESET}"
  else
    # Indent ogni riga della risposta
    while IFS= read -r line; do
      echo -e "${INDENT}${TN_FG}${line}${TN_RESET}"
    done <<< "$1"
  fi
}

# Mostra azioni post-risposta, ritorna 1 se l'utente vuole modificare
_post_actions() {
  echo ""
  echo -e "${TN_DARK}${INDENT}  c  copia · m  modifica · ↵  nuova domanda${TN_RESET}"
  while true; do
    read -rsn 1 key
    case "$key" in
      c|C)
        echo "$1" | pbcopy
        printf "\r\033[K"
        echo -e "${TN_GREEN}${INDENT}  ✓ Copiato negli appunti${TN_RESET}"
        return 0 ;;
      m|M) return 1 ;;
      "")  printf "\r\033[K"; return 0 ;;
    esac
  done
}

# ── MAIN ──────────────────────────────────────────────────────────

clear
_draw_header
echo ""

_check_tokens || { echo ""; read -rp "${INDENT}Premi ENTER per chiudere..." _; exit 1; }
_ensure_deps  || { echo ""; read -rp "${INDENT}Premi ENTER per chiudere..." _; exit 1; }

mkdir -p "$(dirname "$HISTORY_FILE")"

last_query=""
_modify=0

while true; do
  if [[ $_modify -eq 1 && -n "$last_query" ]]; then
    read -re -i "$last_query" -p "$(echo -e "${INDENT}${TN_BLUE}❯${TN_RESET} ")" q 2>/dev/null \
      || { echo -e "${TN_COMMENT}${INDENT}(precedente: $last_query)${TN_RESET}"; \
           read -rp "$(echo -e "${INDENT}${TN_BLUE}❯${TN_RESET} ")" q; }
    _modify=0
  else
    read -rp "$(echo -e "${INDENT}${TN_BLUE}❯${TN_RESET} ")" q
  fi

  [[ -z "$q" ]] && continue
  [[ "$q" == ":q" || "$q" == "exit" || "$q" == "quit" ]] && break

  last_query="$q"
  echo "$q" >> "$HISTORY_FILE"
  echo ""

  _start_spinner
  result=$(_query "$q" 2>&1)
  exit_code=$?
  _stop_spinner

  if [[ $exit_code -ne 0 ]]; then
    echo -e "${TN_YELLOW}${INDENT}$result${TN_RESET}"
  else
    _print_result "$result"
  fi

  _post_actions "$result"
  [[ $? -eq 1 ]] && _modify=1 && continue

  echo ""
  _draw_separator
  echo ""
done

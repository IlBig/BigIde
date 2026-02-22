#!/usr/bin/env bash
# BigIDE — Perplexity interactive REPL
# Tema: Tokyo Night Storm

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

# ── LAYOUT ────────────────────────────────────────────────────────

_cols() { tput cols 2>/dev/null || echo 80; }

_hline() { printf '─%.0s' $(seq 1 "$1"); }

# Unico header fisso in cima — disegnato una sola volta
_draw_header() {
  local cols; cols=$(_cols)
  local inner=$((cols - 2))
  local title=" ● Perplexity "
  local tlen=${#title}
  local ld=$(( (inner - tlen) / 2 ))
  local rd=$(( inner - tlen - ld ))
  echo -e "${TN_DARK}╭$(_hline $ld)${TN_RESET}${TN_BLUE}${TN_BOLD}${title}${TN_RESET}${TN_DARK}$(_hline $rd)╮${TN_RESET}"
}

_draw_separator() {
  local cols; cols=$(_cols)
  echo -e "${TN_DARK}$(_hline $cols)${TN_RESET}"
}

# ── SPINNER ───────────────────────────────────────────────────────

SPINNER_PID=""

_start_spinner() {
  tput civis 2>/dev/null
  (
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    while true; do
      printf "\r ${TN_BLUE}${TN_BOLD}${frames[$((i % 10))]}${TN_RESET}" >&2
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

trap '_stop_spinner' EXIT INT TERM

# ── INIT ──────────────────────────────────────────────────────────

[[ -f "$TOKENS_FILE" ]] && source "$TOKENS_FILE"

_check_tokens() {
  [[ -n "${PERPLEXITY_SESSION_TOKEN:-}" ]] && return 0
  echo -e "${TN_YELLOW} ⚠  Token non configurato${TN_RESET}"
  echo -e "${TN_COMMENT}    perplexity.ai → F12 → Cookies → __Secure-next-auth.session-token${TN_RESET}"
  echo -e "${TN_COMMENT}    Incolla in: ~/.bigide/perplexity/tokens.env${TN_RESET}"
  return 1
}

_ensure_deps() {
  python3 -c "import tls_client" 2>/dev/null && return 0
  pip3 install -q tls-client typing_extensions 2>/dev/null || {
    echo -e "${TN_YELLOW} ⚠  pip3 install tls-client fallito${TN_RESET}"
    return 1
  }
}

_query() {
  PERPLEXITY_SESSION_TOKEN="$PERPLEXITY_SESSION_TOKEN" \
  PERPLEXITY_SEARCH_MODE="$search_mode" \
    python3 "$CLIENT_PY" "$1"
}

_print_result() {
  if command -v glow >/dev/null 2>&1; then
    echo "$1" | glow --width $(( $(_cols) - 4 )) - 2>/dev/null || echo -e " ${TN_FG}$1${TN_RESET}"
  else
    echo -e " ${TN_FG}$1${TN_RESET}"
  fi
}

# ── MAIN ──────────────────────────────────────────────────────────

clear
_draw_header
echo ""

_check_tokens || { echo ""; read -rp "" _; exit 1; }
_ensure_deps  || { echo ""; read -rp "" _; exit 1; }

mkdir -p "$(dirname "$HISTORY_FILE")"

last_query=""
_modify=0
search_mode="standard"

_mode_label() {
  if [[ "$search_mode" == "deep" ]]; then
    echo -e "${TN_DARK}⊕ Approfondita${TN_RESET}"
  else
    echo -e "${TN_COMMENT}○ Ricerca${TN_RESET}"
  fi
}

_prompt_char() {
  if [[ "$search_mode" == "deep" ]]; then
    echo -e "${TN_BLUE}${TN_BOLD}❯${TN_RESET}"
  else
    echo -e "${TN_BLUE}❯${TN_RESET}"
  fi
}

while true; do
  # Modalità corrente sopra il prompt
  echo -e " $(_mode_label)"
  # Salva posizione cursore — [m] tornerà qui
  printf '\033[s'

  if [[ $_modify -eq 1 && -n "$last_query" ]]; then
    _modify=0
    read -re -i "$last_query" \
      -p "$(echo -e " $(_prompt_char) ")" q 2>/dev/null \
      || read -rp "$(echo -e " $(_prompt_char) ")" q
  else
    read -rp "$(echo -e " $(_prompt_char) ")" q
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
    echo -e " ${TN_YELLOW}$result${TN_RESET}"
  else
    _print_result "$result"
  fi

  echo ""
  echo -e " ${TN_COMMENT}c  copia · m  modifica · t  modalità · ↵  nuova${TN_RESET}"

  while true; do
    read -rsn 1 key
    case "$key" in
      c|C)
        echo "$result" | pbcopy
        printf '\033[1A\033[2K'
        echo -e " ${TN_GREEN}✓ Copiato negli appunti${TN_RESET}"
        echo ""
        _draw_separator
        echo ""
        break ;;
      m|M)
        printf '\033[u'
        printf '\033[J'
        _modify=1
        break ;;
      t|T)
        if [[ "$search_mode" == "standard" ]]; then
          search_mode="deep"
        else
          search_mode="standard"
        fi
        printf '\033[1A\033[2K'
        echo -e " ${TN_COMMENT}Modalità: $(_mode_label)${TN_RESET}"
        ;;
      "")
        echo ""
        _draw_separator
        echo ""
        break ;;
    esac
  done

  [[ $_modify -eq 1 ]] && continue
done

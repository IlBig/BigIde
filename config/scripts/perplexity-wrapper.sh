#!/usr/bin/env bash
# BigIDE — Perplexity interactive REPL
# Tema: Tokyo Night Storm — dialog stile LazyVim (bordi su 4 lati)

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

# ── BOX DRAWING ───────────────────────────────────────────────────

_cols() { tput cols 2>/dev/null || echo 80; }

# Riga orizzontale di N caratteri
_hline() { printf '─%.0s' $(seq 1 "$1"); }

# ╭──── ● Perplexity ────╮  (titolo centrato nel bordo)
_box_top() {
  local cols; cols=$(_cols)
  local inner=$((cols - 2))
  local title=" ● Perplexity "
  local tlen=${#title}
  local ld=$(( (inner - tlen) / 2 ))
  local rd=$(( inner - tlen - ld ))
  echo -e "${TN_DARK}╭$(_hline $ld)${TN_RESET}${TN_BLUE}${TN_BOLD}${title}${TN_RESET}${TN_DARK}$(_hline $rd)╮${TN_RESET}"
}

# ╰──────────────────────╯
_box_bottom() {
  local cols; cols=$(_cols)
  local inner=$((cols - 2))
  echo -e "${TN_DARK}╰$(_hline $inner)╯${TN_RESET}"
}

# │  (riga vuota con bordi)
_box_empty() {
  local cols; cols=$(_cols)
  local inner=$((cols - 2))
  echo -e "${TN_DARK}│$(printf ' %.0s' $(seq 1 $inner))│${TN_RESET}"
}

# │  testo  (riga con bordo sx, padding dx calcolato)
_box_line() {
  local text="$1"
  local cols; cols=$(_cols)
  local inner=$((cols - 4))   # │ + spazio sx + contenuto + spazio dx + │
  # Lunghezza visibile (senza ANSI)
  local visible; visible=$(printf '%b' "$text" | sed 's/\033\[[0-9;]*[mGKHFJ]//g')
  local vlen=${#visible}
  local pad=$(( inner - vlen ))
  [[ $pad -lt 0 ]] && pad=0
  echo -e "${TN_DARK}│${TN_RESET} ${text}$(printf ' %.0s' $(seq 1 $pad)) ${TN_DARK}│${TN_RESET}"
}

# Stampa la risposta riga per riga con bordo sx (dx libero per markdown)
_box_response() {
  local rendered
  if command -v glow >/dev/null 2>&1; then
    rendered=$(echo "$1" | glow --width $(( $(_cols) - 6 )) - 2>/dev/null) || rendered="$1"
  else
    rendered="$1"
  fi
  while IFS= read -r line; do
    echo -e "${TN_DARK}│${TN_RESET}  ${TN_FG}${line}${TN_RESET}"
  done <<< "$rendered"
}

# ── SPINNER ───────────────────────────────────────────────────────

SPINNER_PID=""

_start_spinner() {
  tput civis 2>/dev/null
  (
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    while true; do
      printf "\r${TN_DARK}│${TN_RESET} ${TN_BLUE}${TN_BOLD}${frames[$((i % 10))]}${TN_RESET}" >&2
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
  _box_line "${TN_YELLOW}⚠  Token non configurato${TN_RESET}"
  _box_line "${TN_COMMENT}   perplexity.ai → F12 → Cookies → __Secure-next-auth.session-token${TN_RESET}"
  _box_line "${TN_COMMENT}   Incolla in: ~/.bigide/perplexity/tokens.env${TN_RESET}"
  _box_empty
  _box_bottom
  return 1
}

_ensure_deps() {
  python3 -c "import tls_client" 2>/dev/null && return 0
  pip3 install -q tls-client typing_extensions 2>/dev/null || {
    _box_line "${TN_YELLOW}⚠  pip3 install tls-client fallito${TN_RESET}"
    _box_bottom
    return 1
  }
}

_query() {
  PERPLEXITY_SESSION_TOKEN="$PERPLEXITY_SESSION_TOKEN" \
    python3 "$CLIENT_PY" "$1"
}

# ── MAIN ──────────────────────────────────────────────────────────

clear

_check_tokens || { read -rp "" _; exit 1; }
_ensure_deps  || { read -rp "" _; exit 1; }

mkdir -p "$(dirname "$HISTORY_FILE")"

last_query=""
_modify=0

while true; do
  # Apri box
  _box_top
  _box_empty

  # Salva posizione cursore — [m] tornerà qui
  printf '\033[s'

  # Prompt con bordo sx
  if [[ $_modify -eq 1 && -n "$last_query" ]]; then
    _modify=0
    read -re -i "$last_query" \
      -p "$(echo -e "${TN_DARK}│${TN_RESET} ${TN_BLUE}❯${TN_RESET} ")" q 2>/dev/null \
      || read -rp "$(echo -e "${TN_DARK}│${TN_RESET} ${TN_BLUE}❯${TN_RESET} ")" q
  else
    read -rp "$(echo -e "${TN_DARK}│${TN_RESET} ${TN_BLUE}❯${TN_RESET} ")" q
  fi

  [[ -z "$q" ]] && _box_empty && _box_bottom && echo "" && continue
  [[ "$q" == ":q" || "$q" == "exit" || "$q" == "quit" ]] && _box_bottom && break

  last_query="$q"
  echo "$q" >> "$HISTORY_FILE"
  _box_empty

  # Spinner + query
  _start_spinner
  result=$(_query "$q" 2>&1)
  exit_code=$?
  _stop_spinner

  # Risposta
  if [[ $exit_code -ne 0 ]]; then
    _box_line "${TN_YELLOW}$result${TN_RESET}"
  else
    _box_response "$result"
  fi

  # Azioni
  _box_empty
  _box_line "${TN_DARK}c  copia · m  modifica · ↵  nuova domanda${TN_RESET}"
  _box_bottom

  # Gestione tasto
  while true; do
    read -rsn 1 key
    case "$key" in
      c|C)
        echo "$result" | pbcopy
        # Riscrivi l'ultima riga con conferma
        printf '\033[1A\033[2K'
        _box_line "${TN_GREEN}✓ Copiato negli appunti${TN_RESET}"
        _box_bottom
        echo ""
        break ;;
      m|M)
        # Torna al prompt dentro il box
        printf '\033[u'
        printf '\033[J'
        _modify=1
        break ;;
      "")
        echo ""
        break ;;
    esac
  done

  [[ $_modify -eq 1 ]] && continue
done

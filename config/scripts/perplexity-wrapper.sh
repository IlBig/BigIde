#!/usr/bin/env bash
# BigIDE — Perplexity interactive REPL
# Tema: Tokyo Night Storm

TOKENS_FILE="$HOME/.bigide/perplexity/tokens.env"
HISTORY_FILE="$HOME/.bigide/perplexity/history"
CLIENT_PY="$HOME/.bigide/scripts/perplexity/client.py"

# ── CONFIG ────────────────────────────────────────────────────────

PROMPT_CHAR="❯"

# ── TOKYO NIGHT STORM — truecolor ANSI ────────────────────────────
TN_BLUE='\033[38;2;122;162;247m'    # #7aa2f7
TN_GREEN='\033[38;2;158;206;106m'   # #9ece6a
TN_YELLOW='\033[38;2;224;175;104m'  # #e0af68
TN_FG='\033[38;2;192;202;245m'      # #c0caf5
TN_COMMENT='\033[38;2;86;95;137m'   # #565f89
TN_DARK='\033[38;2;65;72;104m'      # #414868
TN_BOLD='\033[1m'
TN_RESET='\033[0m'

# ── HELPERS ───────────────────────────────────────────────────────

_cols() { tput cols 2>/dev/null || echo 80; }

_draw_header() {
  local cols; cols=$(_cols)
  local inner=$((cols - 2))
  local sep; sep=$(printf '─%.0s' $(seq 1 $inner))
  # Testo visibile: " ●  Perplexity   BigIDE" = 23 chars
  local title_visible=" ●  Perplexity   BigIDE"
  local pad; pad=$(printf ' %.0s' $(seq 1 $((inner - ${#title_visible}))))

  echo -e "${TN_DARK}╭${sep}╮${TN_RESET}"
  echo -e "${TN_DARK}│${TN_RESET}${TN_BLUE}${TN_BOLD} ●  Perplexity${TN_RESET}   ${TN_COMMENT}BigIDE${TN_RESET}${pad}${TN_DARK}│${TN_RESET}"
  echo -e "${TN_DARK}╰${sep}╯${TN_RESET}"
}

_draw_separator() {
  local cols; cols=$(_cols)
  local sep; sep=$(printf '─%.0s' $(seq 1 $cols))
  echo -e "${TN_DARK}${sep}${TN_RESET}"
}

# ── INIZIALIZZAZIONE ──────────────────────────────────────────────

[[ -f "$TOKENS_FILE" ]] && source "$TOKENS_FILE"

_check_tokens() {
  [[ -n "${PERPLEXITY_SESSION_TOKEN:-}" ]] && return 0
  echo -e "${TN_YELLOW}⚠  Token non configurato.${TN_RESET}"
  echo -e "   ${TN_COMMENT}1. perplexity.ai → F12 → Cookies → __Secure-next-auth.session-token${TN_RESET}"
  echo -e "   ${TN_COMMENT}2. Incolla in: ~/.bigide/perplexity/tokens.env${TN_RESET}"
  return 1
}

_ensure_deps() {
  python3 -c "import tls_client" 2>/dev/null && return 0
  pip3 install -q tls-client typing_extensions 2>/dev/null || {
    echo -e "${TN_YELLOW}⚠  pip3 install tls-client fallito${TN_RESET}"
    return 1
  }
}

_query() {
  PERPLEXITY_SESSION_TOKEN="$PERPLEXITY_SESSION_TOKEN" \
    python3 "$CLIENT_PY" "$1"
}

_print_result() {
  if command -v glow >/dev/null 2>&1; then
    echo "$1" | glow -
  else
    echo -e "${TN_FG}$1${TN_RESET}"
  fi
}

# Dopo risposta: c=copia, m=modifica, ENTER=nuova domanda
# Restituisce "modify" se l'utente preme m
_post_actions() {
  local result="$1"
  echo ""
  echo -e "${TN_DARK}[c] copia  [m] modifica  [↵] nuova domanda${TN_RESET}"
  while true; do
    read -rsn 1 key
    case "$key" in
      c|C)
        echo "$result" | pbcopy
        echo -e "${TN_GREEN}✓ Copiato${TN_RESET}"
        return 0
        ;;
      m|M)
        return 1  # segnala: vuole modificare
        ;;
      "")  # ENTER
        return 0
        ;;
    esac
  done
}

# ── MAIN LOOP ─────────────────────────────────────────────────────

clear
_draw_header
echo ""

_check_tokens || { read -rp "Premi ENTER per chiudere..." _; exit 1; }
_ensure_deps  || { read -rp "Premi ENTER per chiudere..." _; exit 1; }

mkdir -p "$(dirname "$HISTORY_FILE")"

last_query=""

while true; do
  # Se _post_actions ha segnalato "modifica", pre-popola con l'ultima query
  if [[ -n "$last_query" ]] && [[ "${_modify:-0}" == "1" ]]; then
    read -re -i "$last_query" -p "$(echo -e "${TN_BLUE}${PROMPT_CHAR}${TN_RESET} ")" q
    _modify=0
  else
    read -rp "$(echo -e "${TN_BLUE}${PROMPT_CHAR}${TN_RESET} ")" q
  fi

  [[ -z "$q" ]] && continue
  [[ "$q" == ":q" || "$q" == "exit" || "$q" == "quit" ]] && break

  last_query="$q"
  echo "$q" >> "$HISTORY_FILE"
  echo ""

  result=$(_query "$q" 2>&1)
  exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    echo -e "${TN_YELLOW}$result${TN_RESET}"
  else
    _print_result "$result"
  fi

  _post_actions "$result"
  [[ $? -eq 1 ]] && _modify=1 && echo ""

  echo ""
  _draw_separator
  echo ""
done

echo -e "${TN_COMMENT}Perplexity chiuso.${TN_RESET}"

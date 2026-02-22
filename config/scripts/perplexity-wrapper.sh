#!/usr/bin/env bash
# BigIDE — Perplexity interactive REPL
# Tema: Tokyo Night Storm

TOKENS_FILE="$HOME/.bigide/perplexity/tokens.env"
HISTORY_FILE="$HOME/.bigide/perplexity/history"
CLIENT_PY="$HOME/.bigide/scripts/perplexity/client.py"

# ── CONFIG ────────────────────────────────────────────────────────

PROMPT_CHAR="❯"
SEPARATOR="──────────────────────────────────────────────────────────"

# ── TOKYO NIGHT STORM — truecolor ANSI (\033[38;2;R;G;Bm) ────────
TN_BLUE='\033[38;2;122;162;247m'    # #7aa2f7
TN_CYAN='\033[38;2;125;207;255m'    # #7dcfff
TN_PURPLE='\033[38;2;187;154;247m'  # #bb9af7
TN_GREEN='\033[38;2;158;206;106m'   # #9ece6a
TN_YELLOW='\033[38;2;224;175;104m'  # #e0af68
TN_FG='\033[38;2;192;202;245m'      # #c0caf5
TN_FG_DIM='\033[38;2;169;177;214m'  # #a9b1d6
TN_COMMENT='\033[38;2;86;95;137m'   # #565f89
TN_DARK='\033[38;2;65;72;104m'      # #414868
TN_BOLD='\033[1m'
TN_RESET='\033[0m'

# ── INIZIALIZZAZIONE ──────────────────────────────────────────────

[[ -f "$TOKENS_FILE" ]] && source "$TOKENS_FILE"

_check_tokens() {
  [[ -n "${PERPLEXITY_SESSION_TOKEN:-}" ]] && return 0
  echo -e "${TN_YELLOW}⚠  Token non configurato.${TN_RESET}"
  echo ""
  echo -e "   ${TN_FG_DIM}1. Apri perplexity.ai nel browser${TN_RESET}"
  echo -e "   ${TN_FG_DIM}2. F12 → Application → Cookies → perplexity.ai${TN_RESET}"
  echo -e "   ${TN_FG_DIM}3. Copia: __Secure-next-auth.session-token${TN_RESET}"
  echo -e "   ${TN_FG_DIM}4. Incollalo in: ~/.bigide/perplexity/tokens.env${TN_RESET}"
  echo ""
  return 1
}

_ensure_deps() {
  python3 -c "import tls_client" 2>/dev/null && return 0
  echo -e "${TN_COMMENT}⚙  Installazione tls-client...${TN_RESET}"
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

# ── UI ────────────────────────────────────────────────────────────

clear

# Header
echo -e "${TN_DARK}╭${SEPARATOR}╮${TN_RESET}"
echo -e "${TN_DARK}│${TN_RESET}  ${TN_BLUE}${TN_BOLD}●  Perplexity${TN_RESET}   ${TN_COMMENT}BigIDE${TN_RESET}"
echo -e "${TN_DARK}│${TN_RESET}  ${TN_COMMENT}:q chiudi  ·  Ctrl+C interrompi${TN_RESET}"
echo -e "${TN_DARK}╰${SEPARATOR}╯${TN_RESET}"
echo ""

_check_tokens || { read -rp "Premi ENTER per chiudere..." _; exit 1; }
_ensure_deps  || { read -rp "Premi ENTER per chiudere..." _; exit 1; }

mkdir -p "$(dirname "$HISTORY_FILE")"

while true; do
  read -rp "$(echo -e "${TN_BLUE}${PROMPT_CHAR}${TN_RESET} ")" q

  [[ -z "$q" ]] && continue
  [[ "$q" == ":q" || "$q" == "exit" || "$q" == "quit" ]] && break

  echo "$q" >> "$HISTORY_FILE"
  echo ""
  echo -e "${TN_COMMENT}Ricerca in corso...${TN_RESET}"
  echo ""

  result=$(_query "$q" 2>&1)
  exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    echo -e "${TN_YELLOW}$result${TN_RESET}"
  else
    _print_result "$result"
  fi

  echo ""
  echo -e "${TN_DARK}${SEPARATOR}${TN_RESET}"
  echo ""
done

echo -e "${TN_COMMENT}Perplexity chiuso.${TN_RESET}"

#!/usr/bin/env bash
# BigIDE — Perplexity interactive REPL
# ─────────────────────────────────────────────────────────────────
# PERSONALIZZAZIONE: modifica le variabili nella sezione CONFIG
# ─────────────────────────────────────────────────────────────────

TOKENS_FILE="$HOME/.bigide/perplexity/tokens.env"
HISTORY_FILE="$HOME/.bigide/perplexity/history"
CLIENT_PY="$HOME/.bigide/scripts/perplexity/client.py"

# ── CONFIG ────────────────────────────────────────────────────────

HEADER="  Perplexity  │  BigIDE"
PROMPT="❯"
SEPARATOR="─────────────────────────────────────────────"

# Colori ANSI — svuota la variabile per disabilitare
C_HEADER='\033[1;36m'   # ciano bold  — header
C_PROMPT='\033[0;36m'   # ciano       — prompt
C_DIM='\033[2m'         # dimmed      — "ricerca..."
C_WARN='\033[0;33m'     # giallo      — avvisi
C_RESET='\033[0m'

# ── INIZIALIZZAZIONE ──────────────────────────────────────────────

[[ -f "$TOKENS_FILE" ]] && source "$TOKENS_FILE"

_check_tokens() {
  [[ -n "${PERPLEXITY_SESSION_TOKEN:-}" ]] && return 0
  echo -e "${C_WARN}⚠  Token non configurato.${C_RESET}"
  echo ""
  echo "   1. Apri perplexity.ai nel browser"
  echo "   2. F12 → Application → Cookies → perplexity.ai"
  echo "   3. Copia: __Secure-next-auth.session-token"
  echo "   4. Incollalo in: ~/.bigide/perplexity/tokens.env"
  echo ""
  return 1
}

_ensure_deps() {
  python3 -c "import tls_client" 2>/dev/null && return 0
  echo "⚙  Installazione tls-client..."
  pip3 install -q tls-client typing_extensions 2>/dev/null || {
    echo -e "${C_WARN}⚠  pip3 install tls-client fallito${C_RESET}"
    return 1
  }
}

_query() {
  PERPLEXITY_SESSION_TOKEN="$PERPLEXITY_SESSION_TOKEN" \
    python3 "$CLIENT_PY" "$1"
}

_print_result() {
  local result="$1"
  if command -v glow >/dev/null 2>&1; then
    echo "$result" | glow -
  else
    echo "$result"
  fi
}

# ── UI ────────────────────────────────────────────────────────────

clear
echo -e "${C_HEADER}┌${SEPARATOR}┐"
echo -e "│${HEADER}"
echo -e "│  :q chiudi  │  Ctrl+C interrompi"
echo -e "└${SEPARATOR}┘${C_RESET}"
echo ""

_check_tokens || { read -rp "Premi ENTER per chiudere..." _; exit 1; }
_ensure_deps  || { read -rp "Premi ENTER per chiudere..." _; exit 1; }

mkdir -p "$(dirname "$HISTORY_FILE")"

while true; do
  read -rp "$(echo -e "${C_PROMPT}${PROMPT}${C_RESET} ")" q

  [[ -z "$q" ]] && continue
  [[ "$q" == ":q" || "$q" == "exit" || "$q" == "quit" ]] && break

  echo "$q" >> "$HISTORY_FILE"
  echo ""
  echo -e "${C_DIM}Ricerca in corso...${C_RESET}"
  echo ""

  result=$(_query "$q" 2>&1)
  _print_result "$result"

  echo ""
  echo -e "${C_DIM}${SEPARATOR}${C_RESET}"
  echo ""
done

echo "Perplexity chiuso."

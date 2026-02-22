#!/usr/bin/env bash
# BigIDE — Wrapper interattivo Perplexity
# Interfaccia REPL per query Perplexity dalla sessione web

TOKENS_FILE="$HOME/.bigide/perplexity/tokens.env"
HISTORY_FILE="$HOME/.bigide/perplexity/history"

# Carica token
if [[ -f "$TOKENS_FILE" ]]; then
  source "$TOKENS_FILE"
fi

_check_tokens() {
  if [[ -z "$PERPLEXITY_SESSION_TOKEN" ]]; then
    echo "⚠  Token Perplexity non configurati."
    echo "   Esegui: bigide --setup-perplexity"
    return 1
  fi
}

_query_perplexity() {
  local query="$1"
  local model="${PERPLEXITY_MODEL:-sonar}"

  python3 - "$query" "$PERPLEXITY_SESSION_TOKEN" "${PERPLEXITY_CSRF_TOKEN:-}" << 'PYEOF'
import sys, json, urllib.request, urllib.parse

query = sys.argv[1]
session_token = sys.argv[2]
csrf_token = sys.argv[3] if len(sys.argv) > 3 else ""

headers = {
    "Content-Type": "application/json",
    "Cookie": f"__Secure-next-auth.session-token={session_token}" + (f"; next-auth.csrf-token={csrf_token}" if csrf_token else ""),
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
    "Accept": "application/json",
}

# Usa l'endpoint REST pubblico (non WebSocket) di Perplexity
payload = json.dumps({
    "query": query,
    "search_focus": "internet",
    "attachments": [],
    "language": "it-IT",
    "timezone": "Europe/Rome",
}).encode()

req = urllib.request.Request(
    "https://www.perplexity.ai/rest/sse/perplexity_ask",
    data=payload,
    headers=headers,
    method="POST"
)

try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        last_answer = ""
        for line in resp:
            line = line.decode("utf-8").strip()
            if line.startswith("data:"):
                try:
                    data = json.loads(line[5:])
                    if isinstance(data, dict) and "answer" in data:
                        last_answer = data["answer"]
                except:
                    pass
        if last_answer:
            print(last_answer)
        else:
            print("Nessuna risposta ricevuta.")
except Exception as e:
    print(f"Errore: {e}")
PYEOF
}

# ── UI ─────────────────────────────────────────────────────────────────────────
clear
echo "┌─────────────────────────────────────────┐"
echo "│  🔍  Perplexity  │  BigIDE              │"
echo "│  :q chiudi  │  ↑↓ history              │"
echo "└─────────────────────────────────────────┘"
echo ""

if ! _check_tokens; then
  read -p "Premi ENTER per chiudere..." _
  exit 1
fi

mkdir -p "$(dirname "$HISTORY_FILE")"

while true; do
  # Prompt con readline e history
  if command -v rlwrap >/dev/null 2>&1; then
    read -e -p "❯ " query
  else
    read -p "❯ " query
  fi

  [[ -z "$query" ]] && continue
  [[ "$query" == ":q" || "$query" == "exit" || "$query" == "quit" ]] && break

  echo "$query" >> "$HISTORY_FILE"
  echo ""
  echo "🔄 Ricerca in corso..."
  echo ""

  result=$(_query_perplexity "$query" 2>&1)

  if command -v glow >/dev/null 2>&1; then
    echo "$result" | glow -
  else
    echo "$result"
  fi

  echo ""
  echo "────────────────────────────────────────"
  echo ""
done

echo "Perplexity chiuso."

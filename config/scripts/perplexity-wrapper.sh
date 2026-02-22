#!/usr/bin/env bash
# BigIDE — Wrapper interattivo Perplexity
# Interfaccia REPL per query Perplexity dalla sessione web
# Usa tls-client per bypassare Cloudflare (impersona Chrome TLS fingerprint)

TOKENS_FILE="$HOME/.bigide/perplexity/tokens.env"
HISTORY_FILE="$HOME/.bigide/perplexity/history"

# Carica token
if [[ -f "$TOKENS_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$TOKENS_FILE"
fi

_check_tokens() {
  if [[ -z "${PERPLEXITY_SESSION_TOKEN:-}" ]]; then
    echo "⚠  Token Perplexity non configurati."
    echo ""
    echo "   1. Apri perplexity.ai nel browser"
    echo "   2. F12 → Application → Cookies → perplexity.ai"
    echo "   3. Copia il valore di __Secure-next-auth.session-token"
    echo "   4. Incollalo in: ~/.bigide/perplexity/tokens.env"
    echo ""
    return 1
  fi
}

_ensure_tls_client() {
  python3 -c "import tls_client" 2>/dev/null && return 0
  echo "⚙  Installazione tls-client..."
  pip3 install -q tls-client typing_extensions 2>/dev/null || {
    echo "⚠  Impossibile installare tls-client. Esegui: pip3 install tls-client"
    return 1
  }
}

_query_perplexity() {
  local query="$1"

  python3 - \
    "$query" \
    "${PERPLEXITY_SESSION_TOKEN:-}" \
    "${CF_CLEARANCE:-}" \
    "${CF_BM:-}" \
    << 'PYEOF'
import sys, json

query        = sys.argv[1]
session_tok  = sys.argv[2]
cf_clearance = sys.argv[3]
cf_bm        = sys.argv[4]

try:
    import tls_client
except ImportError:
    print("ERRORE: tls-client non installato. Esegui: pip3 install tls-client")
    sys.exit(1)

sess = tls_client.Session(
    client_identifier="chrome_120",
    random_tls_extension_order=True,
)
sess.headers.update({
    "User-Agent":   "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                    "AppleWebKit/537.36 (KHTML, like Gecko) "
                    "Chrome/120.0.0.0 Safari/537.36",
    "Accept":       "text/event-stream",
    "Content-Type": "application/json",
    "Origin":       "https://www.perplexity.ai",
    "Referer":      "https://www.perplexity.ai/",
})

cookies = {"__Secure-next-auth.session-token": session_tok}
if cf_clearance:
    cookies["cf_clearance"] = cf_clearance
if cf_bm:
    cookies["__cf_bm"] = cf_bm
sess.cookies.update(cookies)

payload = {
    "query_str":    query,
    "search_focus": "internet",
    "attachments":  [],
    "language":     "it-IT",
    "timezone":     "Europe/Rome",
}

try:
    resp = sess.post(
        "https://www.perplexity.ai/rest/sse/perplexity_ask",
        json=payload,
    )
except Exception as e:
    print(f"ERRORE connessione: {e}")
    sys.exit(1)

if resp.status_code == 403:
    print("ERRORE 403: cf_clearance scaduto o non valido.")
    print("Aggiorna CF_CLEARANCE in ~/.bigide/perplexity/tokens.env")
    sys.exit(1)

if resp.status_code != 200:
    print(f"ERRORE HTTP {resp.status_code}: {resp.text[:200]}")
    sys.exit(1)

# Parsing SSE stream
# Il protocollo Perplexity invia messaggi incrementali con campo "text".
# Quando text_completed=True, "text" contiene un JSON array di step.
# L'ultimo step ha step_type="FINAL" con content.answer (JSON-encoded string).
last_completed_text = ""
for line in resp.text.splitlines():
    line = line.strip()
    if not line.startswith("data:"):
        continue
    raw = line[5:].strip()
    if not raw or raw == "[DONE]":
        continue
    try:
        data = json.loads(raw)
        if isinstance(data, dict) and data.get("text_completed") and data.get("text"):
            last_completed_text = data["text"]
    except json.JSONDecodeError:
        pass

if not last_completed_text:
    print("Nessuna risposta ricevuta.")
    sys.exit(0)

# Estrai risposta dal FINAL step
try:
    steps = json.loads(last_completed_text)
    for step in reversed(steps):
        if step.get("step_type") == "FINAL":
            content = step.get("content", {})
            answer_raw = content.get("answer", "")
            if answer_raw:
                try:
                    # answer è una stringa JSON contenente {"answer": "..."}
                    answer_data = json.loads(answer_raw)
                    final = answer_data.get("answer", answer_raw)
                except json.JSONDecodeError:
                    final = answer_raw
                print(final)
                sys.exit(0)
except (json.JSONDecodeError, TypeError):
    # Fallback: stampa testo grezzo
    print(last_completed_text[:3000])

print("Nessuna risposta nel FINAL step.")
PYEOF
}

# ── UI ─────────────────────────────────────────────────────────────────────────
clear
echo "┌──────────────────────────────────────────┐"
echo "│  Perplexity  │  BigIDE                   │"
echo "│  :q chiudi   │  Ctrl+C interrompi         │"
echo "└──────────────────────────────────────────┘"
echo ""

if ! _check_tokens; then
  read -rp "Premi ENTER per chiudere..." _
  exit 1
fi

if ! _ensure_tls_client; then
  read -rp "Premi ENTER per chiudere..." _
  exit 1
fi

mkdir -p "$(dirname "$HISTORY_FILE")"

while true; do
  if command -v rlwrap >/dev/null 2>&1; then
    read -re -p "❯ " query
  else
    read -rp "❯ " query
  fi

  [[ -z "$query" ]] && continue
  [[ "$query" == ":q" || "$query" == "exit" || "$query" == "quit" ]] && break

  echo "$query" >> "$HISTORY_FILE"
  echo ""
  echo "Ricerca in corso..."
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

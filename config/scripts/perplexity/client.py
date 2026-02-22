#!/usr/bin/env python3
"""
BigIDE — Perplexity Client

Invia una query a Perplexity usando la sessione web (nessuna API key).
Usa tls-client per bypassare Cloudflare con fingerprint Chrome.

Utilizzo:
  python3 client.py "la tua domanda"

Legge PERPLEXITY_SESSION_TOKEN dall'ambiente.
"""

import sys
import json
import os

# ── CONFIGURAZIONE ─────────────────────────────────────────────────────────────
# Modifica queste costanti per personalizzare il comportamento

LANGUAGE = "it-IT"
TIMEZONE = "Europe/Rome"
FOCUS    = "internet"   # internet | writing | wolfram | youtube | reddit

USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/120.0.0.0 Safari/537.36"
)

ENDPOINT = "https://www.perplexity.ai/rest/sse/perplexity_ask"

# ──────────────────────────────────────────────────────────────────────────────


def _make_session(token: str):
    try:
        import tls_client
    except ImportError:
        print("ERRORE: tls-client non installato. Esegui: pip3 install tls-client",
              file=sys.stderr)
        sys.exit(1)

    sess = tls_client.Session(
        client_identifier="chrome_120",
        random_tls_extension_order=True,
    )
    sess.headers.update({
        "User-Agent":   USER_AGENT,
        "Accept":       "text/event-stream",
        "Content-Type": "application/json",
        "Origin":       "https://www.perplexity.ai",
        "Referer":      "https://www.perplexity.ai/",
    })
    sess.cookies.update({"__Secure-next-auth.session-token": token})
    return sess


def _parse_sse(text: str) -> str:
    """Estrae la risposta markdown dallo stream SSE di Perplexity."""
    last_completed = ""
    for line in text.splitlines():
        line = line.strip()
        if not line.startswith("data:"):
            continue
        raw = line[5:].strip()
        if not raw or raw == "[DONE]":
            continue
        try:
            data = json.loads(raw)
            if isinstance(data, dict) and data.get("text_completed") and data.get("text"):
                last_completed = data["text"]
        except json.JSONDecodeError:
            pass

    if not last_completed:
        return ""

    try:
        steps = json.loads(last_completed)
        for step in reversed(steps):
            if step.get("step_type") == "FINAL":
                raw_ans = step.get("content", {}).get("answer", "")
                if raw_ans:
                    try:
                        return json.loads(raw_ans).get("answer", raw_ans)
                    except json.JSONDecodeError:
                        return raw_ans
    except (json.JSONDecodeError, TypeError):
        pass

    return last_completed


def query(text: str) -> str:
    """Invia una query e restituisce la risposta in markdown."""
    token = os.environ.get("PERPLEXITY_SESSION_TOKEN", "").strip()
    if not token:
        print("ERRORE: PERPLEXITY_SESSION_TOKEN non impostato", file=sys.stderr)
        sys.exit(1)

    sess = _make_session(token)

    try:
        resp = sess.post(ENDPOINT, json={
            "query_str":    text,
            "search_focus": FOCUS,
            "attachments":  [],
            "language":     LANGUAGE,
            "timezone":     TIMEZONE,
        })
    except Exception as e:
        print(f"ERRORE connessione: {e}", file=sys.stderr)
        sys.exit(1)

    if resp.status_code == 403:
        print("ERRORE 403: sessione scaduta. Aggiorna PERPLEXITY_SESSION_TOKEN in "
              "~/.bigide/perplexity/tokens.env", file=sys.stderr)
        sys.exit(1)

    if resp.status_code != 200:
        print(f"ERRORE HTTP {resp.status_code}: {resp.text[:200]}", file=sys.stderr)
        sys.exit(1)

    answer = _parse_sse(resp.text)
    if not answer:
        print("Nessuna risposta ricevuta.", file=sys.stderr)
        sys.exit(1)

    return answer


if __name__ == "__main__":
    if len(sys.argv) < 2 or not sys.argv[1].strip():
        print("Uso: python3 client.py \"la tua domanda\"", file=sys.stderr)
        sys.exit(1)

    print(query(sys.argv[1]))

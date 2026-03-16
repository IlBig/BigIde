#!/usr/bin/env bash
# @name: Commit & Push
# @desc: Stage + commit con messaggio AI + push automatico
# @icon:
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Usa la directory corrente del terminale (non forzare cd)

# ─── Colori ──────────────────────────────────────────────────────────────────
G=$'\033[38;2;158;206;106m'    # green
C=$'\033[38;2;125;207;255m'    # cyan
D=$'\033[38;2;86;95;137m'      # dim
W=$'\033[38;2;192;202;245m'    # white
R=$'\033[0m'

# ─── Check modifiche ────────────────────────────────────────────────────────
if git diff --cached --quiet 2>/dev/null \
   && git diff --quiet 2>/dev/null \
   && [ -z "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
  echo ""
  echo "  ${D}Nessuna modifica da committare.${R}"
  echo ""
  echo "  ${D}Premi un tasto per chiudere...${R}"
  read -rsn1
  exit 0
fi

# ─── Stage ───────────────────────────────────────────────────────────────────
echo ""
echo "  ${C}Stage modifiche...${R}"
git add -A
echo ""

# Mostra riepilogo
echo "  ${W}Modifiche:${R}"
git diff --cached --stat | sed 's/^/    /'
echo ""

# ─── Genera messaggio commit con AI ─────────────────────────────────────────
echo "  ${C}Generazione messaggio commit con AI...${R}"
echo ""

diff_content="$(git diff --cached)"

# Tronca diff grandi per risparmiare token
diff_bytes="$(printf '%s' "$diff_content" | wc -c)"
if [ "$diff_bytes" -gt 8000 ]; then
  diff_summary="$(git diff --cached --stat)"
  diff_content="${diff_summary}

$(printf '%s' "$diff_content" | LC_ALL=C cut -c1-8000)
... (troncato)"
fi

# Genera messaggio con API diretta (se ANTHROPIC_API_KEY è settata) o claude CLI
_api_key="${ANTHROPIC_API_KEY:-}"
commit_msg=""

if [[ -n "$_api_key" ]]; then
  # API key disponibile → curl diretto (~1-2s)
  _prompt="Analizza questo diff git e genera UN SOLO messaggio di commit in stile conventional commits (feat:, fix:, refactor:, docs:, chore:, etc.). Massimo 72 caratteri per la prima riga. Se serve, aggiungi un body breve dopo una riga vuota. Rispondi SOLO con il messaggio di commit, niente altro."
  _payload="$(jq -cn --arg diff "$diff_content" --arg prompt "$_prompt" '{
    model: "claude-haiku-4-5-20251001",
    max_tokens: 256,
    messages: [{role: "user", content: ($prompt + "\n\n" + $diff)}]
  }')"
  _resp="$(curl -s --max-time 15 \
    -H "x-api-key: $_api_key" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "$_payload" \
    "https://api.anthropic.com/v1/messages" 2>/dev/null)" || true
  commit_msg="$(echo "$_resp" | jq -r '.content[0].text // empty' 2>/dev/null)" || true
fi

if [[ -z "$commit_msg" ]]; then
  # Fallback: claude CLI (più lento, ~10s di startup)
  commit_msg="$(printf '%s' "$diff_content" | claude -p \
    "Analizza questo diff git e genera UN SOLO messaggio di commit in stile conventional commits (feat:, fix:, refactor:, docs:, chore:, etc.). Massimo 72 caratteri per la prima riga. Se serve, aggiungi un body breve dopo una riga vuota. Rispondi SOLO con il messaggio di commit, niente altro." \
    --model haiku 2>/dev/null)" || true
fi

if [[ -z "$commit_msg" ]]; then
  echo "  ${D}AI non disponibile, inserisci messaggio manualmente.${R}"
  echo ""
  read -rp "  Messaggio: " commit_msg
  if [[ -z "$commit_msg" ]]; then
    echo "  ${D}Commit annullato.${R}"
    echo ""
    echo "  ${D}Premi un tasto per chiudere...${R}"
    read -rsn1
    exit 0
  fi
else
  echo "  ${W}Messaggio proposto:${R}"
  echo "  ${G}${commit_msg}${R}"
  echo ""
  read -rp "  Confermi? [s]ì / [m]odifica / [n]o: " choice
  case "${choice:-s}" in
    m|M)
      read -rp "  Nuovo messaggio: " commit_msg
      [[ -z "$commit_msg" ]] && { echo "  ${D}Annullato.${R}"; read -rsn1; exit 0; }
      ;;
    n|N)
      echo ""
      echo "  ${D}Commit annullato.${R}"
      git reset HEAD >/dev/null 2>&1 || true
      echo ""
      echo "  ${D}Premi un tasto per chiudere...${R}"
      read -rsn1
      exit 0
      ;;
  esac
fi

# ─── Commit ──────────────────────────────────────────────────────────────────
echo ""
printf '%s\n' "$commit_msg" | git commit -F -
echo ""

# ─── Push ────────────────────────────────────────────────────────────────────
echo "  ${C}Push in corso...${R}"
echo ""
git push 2>&1 || {
  echo ""
  echo "  ${D}Push fallito. Prova manualmente.${R}"
  echo ""
  echo "  ${D}Premi un tasto per chiudere...${R}"
  read -rsn1
  exit 0
}

echo ""
echo "  ${G}✓ Commit e push completati${R}"
echo ""
echo "  ${D}Premi un tasto per chiudere...${R}"
read -rsn1

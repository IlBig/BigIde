#!/usr/bin/env bash
set -euo pipefail

# ── BigIDE Bootstrap ─────────────────────────────────────────────────────────
# Eseguito da Terminal.app quando BigIDE.app rileva che manca qualcosa
# (Ghostty non installato, ~/.bigide non configurato, ecc.)
# Mostra progressi all'utente, installa tutto, lancia Ghostty, chiude Terminal.

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# ── Colori ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# ── Repo root (passato come env var dal launcher) ─────────────────────────────
if [[ -z "${BIGIDE_REPO_ROOT:-}" ]]; then
  echo -e "${RED}Errore: BIGIDE_REPO_ROOT non impostato${NC}"
  echo "Questo script va lanciato da BigIDE.app"
  read -n1 -rsp "Premi un tasto per chiudere..."
  exit 1
fi

if [[ ! -d "$BIGIDE_REPO_ROOT/src/shell/lib" ]]; then
  echo -e "${RED}Errore: Repository BigIDE non trovato in $BIGIDE_REPO_ROOT${NC}"
  read -n1 -rsp "Premi un tasto per chiudere..."
  exit 1
fi

# ── Source librerie ───────────────────────────────────────────────────────────
source "$BIGIDE_REPO_ROOT/src/shell/lib/common.sh"
source "$BIGIDE_REPO_ROOT/src/shell/lib/deps.sh"
source "$BIGIDE_REPO_ROOT/src/shell/lib/setup-runtime.sh"

# ── Banner ────────────────────────────────────────────────────────────────────
clear
echo ""
echo -e "${BLUE}${BOLD}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║          BigIDE — Setup              ║"
echo "  ║      Prima installazione...          ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# ── Step 1: Dipendenze ───────────────────────────────────────────────────────
echo -e "${YELLOW}▸ [1/2]${NC} Installazione dipendenze..."
echo ""

if ensure_dependencies; then
  echo ""
  echo -e "  ${GREEN}✔${NC} Dipendenze installate"
else
  echo ""
  echo -e "  ${YELLOW}⚠${NC} Alcune dipendenze non installate (controlla il log)"
fi

# ── Step 2: Runtime ──────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}▸ [2/2]${NC} Configurazione runtime..."
echo ""

if init_runtime; then
  echo ""
  echo -e "  ${GREEN}✔${NC} Runtime configurato"
else
  echo ""
  echo -e "  ${YELLOW}⚠${NC} Configurazione runtime parziale (controlla il log)"
fi

# ── Lancia Ghostty ────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}  ✔ Setup completato!${NC}"
echo ""

GHOSTTY_CONFIG="$BIGIDE_HOME/ghostty/config"

# Cerca Ghostty (appena installato)
GHOSTTY_BIN=""
for candidate in \
  "/Applications/Ghostty.app/Contents/MacOS/ghostty" \
  "$HOME/Applications/Ghostty.app/Contents/MacOS/ghostty" \
  "/Volumes/Macintosh_EXT/big_ext/Applications/Ghostty.app/Contents/MacOS/ghostty"; do
  [[ -x "$candidate" ]] && GHOSTTY_BIN="$candidate" && break
done
if [[ -z "$GHOSTTY_BIN" ]]; then
  local_app="$(mdfind 'kMDItemCFBundleIdentifier == "com.mitchellh.ghostty"' 2>/dev/null | head -1)"
  [[ -n "$local_app" ]] && GHOSTTY_BIN="$local_app/Contents/MacOS/ghostty"
fi

if [[ -x "$GHOSTTY_BIN" && -f "$GHOSTTY_CONFIG" ]]; then
  echo -e "  Lancio ${BOLD}Ghostty${NC}..."
  nohup "$GHOSTTY_BIN" --config-file="$GHOSTTY_CONFIG" >/dev/null 2>&1 &
  sleep 1
  # Chiudi questa finestra di Terminal.app
  osascript -e 'tell application "Terminal" to close front window' 2>/dev/null || true
else
  echo -e "  ${YELLOW}Ghostty non trovato o config mancante.${NC}"
  echo -e "  Lancia ${BOLD}bigide${NC} manualmente dal terminale."
  echo ""
  read -n1 -rsp "Premi un tasto per chiudere..."
fi

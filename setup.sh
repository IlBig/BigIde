#!/usr/bin/env bash
set -euo pipefail

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

check_cmd() { command -v "$1" >/dev/null 2>&1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Verifica OS
if [[ "$(uname)" != "Darwin" ]]; then
  warn "BigIDE è ottimizzato per macOS. Linux è supportato sperimentalmente."
fi

# 2. Installa Homebrew se necessario
if ! check_cmd brew; then
  info "Installazione Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 3. Installa dipendenze sistema
info "Verifica e installazione dipendenze sistema..."
DEPENDENCIES=(tmux jq git yazi broot node gh ffmpeg)
MISSING=()

for dep in "${DEPENDENCIES[@]}"; do
  if ! check_cmd "$dep"; then
    MISSING+=("$dep")
  else
    info "  $dep: Presente"
  fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  info "Installazione mancanti: ${MISSING[*]}"
  brew install "${MISSING[@]}" || warn "Alcune installazioni sono fallite. Controlla manualmente."
fi

# Ghostty (Cask su macOS)
if ! check_cmd ghostty; then
  info "Installazione ghostty..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install --cask ghostty || warn "Impossibile installare ghostty via brew cask."
  else
    warn "Installa ghostty manualmente per il tuo sistema."
  fi
fi

# Gitmux (tap dedicato)
if ! check_cmd gitmux; then
  info "Installazione gitmux..."
  brew tap arl/arl
  brew install gitmux || warn "Impossibile installare gitmux."
fi

# Whisper.cpp (per voce)
if ! check_cmd whisper-cpp; then
  info "Installazione whisper-cpp..."
  brew install whisper-cpp || warn "Impossibile installare whisper-cpp."
fi

# 4. Installa Claude Code e Memoria
if ! check_cmd claude; then
  info "Installazione Claude Code..."
  npm install -g @anthropic-ai/claude-code || warn "Impossibile installare Claude Code globalmente via npm."
else
  info "Claude Code: Presente"
fi

if ! check_cmd bun; then
  info "Installazione Bun..."
  curl -fsSL https://bun.sh/install | bash || warn "Impossibile installare Bun."
fi

if ! check_cmd uv; then
  info "Installazione uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh || warn "Impossibile installare uv."
fi

if ! check_cmd perplexity; then
  info "Installazione Perplexity CLI..."
  npm install -g perplexity-cli || warn "Impossibile installare Perplexity CLI."
fi

# 5. Build Server MCP BigIDE
info "Build server MCP..."
cd "$SCRIPT_DIR/src/mcp"
if [[ ! -d "node_modules" ]]; then
  npm install
fi
npm run build
cd "$SCRIPT_DIR"

# 5.5 Installazione claude-mem (plugin)
if ! check_cmd claude-mem; then
  info "Installazione plugin claude-mem..."
  # Simula installazione via npm globale o suggerimento
  # npm install -g @thedotmack/claude-mem || true
  # In Phase 2 l'architettura dice "Usare claude-mem as-is"
fi

# 6. Setup Runtime iniziale
info "Setup runtime BigIDE..."
mkdir -p ~/.bigide/logs ~/.bigide/layouts ~/.bigide/tmux ~/.bigide/mcp ~/.bigide/memory
# Copia configurazioni di default
cp -n "$SCRIPT_DIR/config/default-config.json" ~/.bigide/config.json || true
cp -f "$SCRIPT_DIR/config/tmux.conf" ~/.bigide/tmux/tmux.conf
cp -r "$SCRIPT_DIR/config/layouts" ~/.bigide/
cp -r "$SCRIPT_DIR/src/shell/scripts" ~/.bigide/
cp -r "$SCRIPT_DIR/config/nvim" ~/.bigide/
chmod +x ~/.bigide/scripts/*.sh
cp -f "$SCRIPT_DIR/config/gitmux.conf" ~/.bigide/gitmux.conf 2>/dev/null || true

# 7. Registra alias e env vars
# L'utente dovrebbe usare NVIM_APPNAME=bigide per questo config


# Copia MCP build
rm -rf ~/.bigide/mcp/dist
mkdir -p ~/.bigide/mcp/dist
cp -r "$SCRIPT_DIR/src/mcp/dist" ~/.bigide/mcp/
cp "$SCRIPT_DIR/src/mcp/package.json" ~/.bigide/mcp/

# Installa deps runtime MCP (solo prod)
cd ~/.bigide/mcp
npm install --omit=dev --no-package-lock
cd "$SCRIPT_DIR"

info "Installazione completata!"
info "Puoi avviare BigIDE con: ./bin/bigide"
info "Suggerimento: aggiungi 'alias bigide=$PWD/bin/bigide' al tuo .zshrc"

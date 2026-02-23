#!/usr/bin/env bash
set -euo pipefail

# ── Dipendenze BigIDE ─────────────────────────────────────────────────────────
# Formato: "pacchetto-brew:comando-check"  (se uguale basta il nome)
_BREW_DEPS=(
  "tmux:tmux"
  "jq:jq"
  "git:git"
  "yazi:yazi"
  "neovim:nvim"
  "node:node"
  "gh:gh"
  "ffmpeg:ffmpeg"
  "whisper-cpp:whisper-cli"
  "timg:timg"      # anteprima immagini/video nel terminale (neo-tree binary preview)
  "chafa:chafa"    # fallback rendering immagini (block chars)
)
_BREW_CASKS=(ghostty)
_NPM_GLOBALS=("@anthropic-ai/claude-code:claude" "perplexity-cli:perplexity")

# Disabilita auto-update brew (lento e blocca l'avvio)
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_UPGRADE=1

_check_cmd() { command -v "$1" >/dev/null 2>&1; }

_ensure_brew() {
  if ! _check_cmd brew; then
    log "INFO" "Installazione Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

_ensure_brew_deps() {
  local missing=()
  for entry in "${_BREW_DEPS[@]}"; do
    local pkg="${entry%%:*}"
    local cmd="${entry##*:}"
    _check_cmd "$cmd" || missing+=("$pkg")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    log "INFO" "Installazione dipendenze mancanti: ${missing[*]}"
    brew install "${missing[@]}" || log "WARN" "Alcune installazioni brew non riuscite"
  fi
}

_ensure_brew_casks() {
  if [[ "$(uname)" != "Darwin" ]]; then return; fi
  for cask in "${_BREW_CASKS[@]}"; do
    if ! _check_cmd "$cask"; then
      log "INFO" "Installazione $cask..."
      brew install --cask "$cask" || log "WARN" "Impossibile installare $cask"
    fi
  done
}

_ensure_gitmux() {
  if ! _check_cmd gitmux; then
    log "INFO" "Installazione gitmux..."
    brew tap arl/arl 2>/dev/null && brew install gitmux || log "WARN" "Impossibile installare gitmux"
  fi
}

_ensure_npm_globals() {
  for entry in "${_NPM_GLOBALS[@]}"; do
    local pkg="${entry%%:*}"
    local cmd="${entry##*:}"
    if ! _check_cmd "$cmd"; then
      log "INFO" "Installazione $pkg..."
      npm install -g "$pkg" || log "WARN" "Impossibile installare $pkg"
    fi
  done
}

_ensure_bun() {
  _check_cmd bun && return
  [[ -x "$HOME/.bun/bin/bun" ]] && return  # installato ma non ancora in PATH
  log "INFO" "Installazione Bun..."
  curl -fsSL https://bun.sh/install | bash || log "WARN" "Impossibile installare Bun"
}

_ensure_uv() {
  _check_cmd uv && return
  [[ -x "$HOME/.local/bin/uv" ]] && return  # installato ma non ancora in PATH
  log "INFO" "Installazione uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh || log "WARN" "Impossibile installare uv"
}

_ensure_mcp_build() {
  local dist="$BIGIDE_REPO_ROOT/src/mcp/dist/index.js"
  [[ -f "$dist" ]] && return
  log "INFO" "Build MCP server..."
  (cd "$BIGIDE_REPO_ROOT/src/mcp" && npm install && npm run build) \
    || log "WARN" "Build MCP non riuscita"
}

_ensure_pip_deps() {
  # tls-client: bypass Cloudflare per wrapper Perplexity (impersona TLS Chrome)
  if ! python3 -c "import tls_client" 2>/dev/null; then
    log "INFO" "Installazione tls-client..."
    pip3 install -q tls-client typing_extensions 2>/dev/null \
      || log "WARN" "Impossibile installare tls-client"
  fi
}

# ── Entry point principale ────────────────────────────────────────────────────

ensure_dependencies() {
  _ensure_brew
  _ensure_brew_deps
  _ensure_brew_casks
  _ensure_gitmux
  _ensure_npm_globals
  _ensure_bun
  _ensure_uv
  _ensure_mcp_build
  _ensure_pip_deps
  # LazyVim plugins installati da init_runtime() dopo copia config
}

# Verifica rapida (solo check, no install) — usata per messaggi diagnostici
check_dependencies() {
  local ok=1
  for cmd in tmux jq git nvim claude; do
    if ! _check_cmd "$cmd"; then
      log "WARN" "Dipendenza mancante: $cmd (verrà installata automaticamente)"
      ok=0
    fi
  done
  return 0  # non bloccare: ensure_dependencies gestisce l'installazione
}

#!/usr/bin/env bash
set -euo pipefail

# ── Dipendenze BigIDE ─────────────────────────────────────────────────────────

_BREW_DEPS=(tmux jq git yazi neovim node gh ffmpeg whisper-cpp)
_BREW_CASKS=(ghostty)
_NPM_GLOBALS=("@anthropic-ai/claude-code:claude" "perplexity-cli:perplexity")

_check_cmd() { command -v "$1" >/dev/null 2>&1; }

_ensure_brew() {
  if ! _check_cmd brew; then
    log "INFO" "Installazione Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

_ensure_brew_deps() {
  local missing=()
  for dep in "${_BREW_DEPS[@]}"; do
    _check_cmd "$dep" || missing+=("$dep")
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
  log "INFO" "Installazione Bun..."
  curl -fsSL https://bun.sh/install | bash || log "WARN" "Impossibile installare Bun"
}

_ensure_uv() {
  _check_cmd uv && return
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

_ensure_lazyvim_plugins() {
  local lazy_dir="${XDG_DATA_HOME:-$HOME/.local/share}/bigide/lazy/lazy.nvim"
  [[ -d "$lazy_dir" ]] && return
  log "INFO" "Installazione plugin LazyVim (solo prima volta)..."
  NVIM_APPNAME=bigide nvim --headless "+Lazy! sync" +qa 2>/dev/null \
    || log "WARN" "Installazione plugin LazyVim non completata, verrà riprovata al prossimo avvio"
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
  _ensure_lazyvim_plugins
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

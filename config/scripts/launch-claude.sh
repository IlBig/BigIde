#!/usr/bin/env bash
set -euo pipefail

# Ensure common paths for macOS
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

BIGIDE_REPO_ROOT="${BIGIDE_REPO_ROOT:-__BIGIDE_REPO_ROOT__}"
BIGIDE_HOME="${BIGIDE_HOME:-$HOME/.bigide}"

source "$BIGIDE_REPO_ROOT/src/shell/lib/common.sh"
source "$BIGIDE_REPO_ROOT/src/shell/lib/ccproxy.sh"

log "INFO" "Avvio Claude Code..."

# 1. Configurazione MCP
CONFIG_DIR="$HOME/.claude"
CONFIG_FILE="$CONFIG_DIR/config.json"
MCP_PATH="$BIGIDE_HOME/mcp/dist/index.js"

mkdir -p "$CONFIG_DIR"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "{}" > "$CONFIG_FILE"
fi

# 1.1 Server BigIDE MCP
if ! grep -q "tmux-mcp" "$CONFIG_FILE"; then
  log "INFO" "Registrazione server MCP BigIDE..."
  if command -v claude >/dev/null 2>&1; then
     # Try adding it via the new 'mcp add' command if supported, else manual jq
     if claude --help | grep -q "mcp"; then
       claude mcp add tmux-mcp node "$MCP_PATH" || true
     else
       TMP=$(mktemp)
       jq --arg path "$MCP_PATH" '.mcpServers["tmux-mcp"] = { command: "node", args: [$path] }' "$CONFIG_FILE" > "$TMP" && mv "$TMP" "$CONFIG_FILE"
     fi
  fi
fi

# 2. Avvio Claude
# Rimuove CLAUDECODE: evita errore "nested session" se BigIDE è aperto da un terminale
# che ha già una sessione Claude attiva (es. durante sviluppo)
unset CLAUDECODE 2>/dev/null || true

if command -v claude >/dev/null 2>&1; then
  clear
  launch_claude_with_proxy
else
  log "ERROR" "Claude Code non trovato in PATH. Installa con: npm install -g @anthropic-ai/claude-code"
  echo "Claude Code non trovato."
  sleep 10
fi

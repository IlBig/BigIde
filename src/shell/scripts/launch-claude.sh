#!/usr/bin/env bash

# Configurazione MCP
CONFIG_DIR="$HOME/.claude"
CONFIG_FILE="$CONFIG_DIR/config.json"
MCP_PATH="$HOME/.bigide/mcp/dist/index.js"

mkdir -p "$CONFIG_DIR"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "{}" > "$CONFIG_FILE"
fi

# Verifica se il server è già configurato (basic check)
if ! grep -q "tmux-mcp" "$CONFIG_FILE"; then
  echo "Configuring BigIDE MCP server..."
  if command -v claude >/dev/null 2>&1; then
     if claude --help | grep -q "mcp"; then
       claude mcp add tmux-mcp node "$MCP_PATH"
     else
       TMP=$(mktemp)
       jq --arg path "$MCP_PATH" '.mcpServers["tmux-mcp"] = { command: "node", args: [$path] }' "$CONFIG_FILE" > "$TMP" && mv "$TMP" "$CONFIG_FILE"
     fi
  fi
fi

# Configurazione Memoria MCP (claude-mem)
if ! grep -q "claude-mem" "$CONFIG_FILE"; then
  if command -v claude-mem >/dev/null 2>&1; then
    info "Configuring Memory MCP..."
    claude mcp add claude-mem npx -y @thedotmack/claude-mem
  fi
fi

exec claude

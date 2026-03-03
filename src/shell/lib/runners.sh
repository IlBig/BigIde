#!/usr/bin/env bash
set -euo pipefail

# ── BigIDE Runner: lancia la CLI nativa del provider selezionato ─────────────
#
# Provider:
#   anthropic → claude --dangerously-skip-permissions
#   openai    → codex
#   gemini    → gemini
#
# Struttura:
#   ~/.bigide/active-runner → "anthropic" | "openai" | "gemini"

ACTIVE_RUNNER_FILE="$BIGIDE_HOME/active-runner"

# ── Runner helper ─────────────────────────────────────────────────────────────

get_active_runner() {
  # Per-window: prova tmux window option (senza -t = window corrente del pane)
  local wr
  wr="$(tmux show-option -wqv @bigide_runner 2>/dev/null)" || true
  if [[ -n "$wr" ]]; then
    echo "$wr"
    return 0
  fi
  # Fallback: file globale
  if [[ -f "$ACTIVE_RUNNER_FILE" ]]; then
    cat "$ACTIVE_RUNNER_FILE" 2>/dev/null
  else
    echo "anthropic"
  fi
}

# ── MCP setup (solo Anthropic/Claude) ─────────────────────────────────────────

_ensure_mcp_registered() {
  local config_dir="$1"
  local config_file="$config_dir/config.json"
  local mcp_path="$BIGIDE_HOME/mcp/dist/index.js"

  mkdir -p "$config_dir"
  [[ -f "$config_file" ]] || echo "{}" > "$config_file"

  if ! grep -q "tmux-mcp" "$config_file" 2>/dev/null; then
    local tmp
    tmp=$(mktemp)
    jq --arg path "$mcp_path" '.mcpServers["tmux-mcp"] = { command: "node", args: [$path] }' \
      "$config_file" > "$tmp" && mv "$tmp" "$config_file"
    log "INFO" "MCP tmux-mcp registrato in $config_file"
  fi
}

# ── Launch ────────────────────────────────────────────────────────────────────

launch_claude() {
  local runner
  runner="$(get_active_runner)"

  log "INFO" "Provider: $runner"

  # Rimuove CLAUDECODE per evitare errore "nested session"
  unset CLAUDECODE 2>/dev/null || true

  case "$runner" in
    anthropic)
      _ensure_mcp_registered "$HOME/.claude"
      log "INFO" "Avvio Claude (Anthropic)"
      exec claude --dangerously-skip-permissions "$@"
      ;;
    openai)
      log "INFO" "Avvio Codex (OpenAI)"
      exec codex
      ;;
    gemini)
      log "INFO" "Avvio Gemini (Google)"
      exec gemini --yolo
      ;;
    *)
      log "WARN" "Provider '$runner' sconosciuto, fallback Anthropic"
      _ensure_mcp_registered "$HOME/.claude"
      exec claude --dangerously-skip-permissions "$@"
      ;;
  esac
}

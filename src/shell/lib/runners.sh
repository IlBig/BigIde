#!/usr/bin/env bash
set -euo pipefail

# ── BigIDE Runner: gestione profili multi-provider per Claude Code ──────────
#
# Approccio:
#   Anthropic (nativo)  → claude --model <alias>  (auth via ~/.claude)
#   OpenAI / Gemini     → LiteLLM proxy (127.0.0.1:4000) traduce Anthropic → nativo
#   Runner custom       → CLAUDE_CONFIG_DIR=<runner_dir> claude
#
# Struttura:
#   ~/.bigide/active-runner    → "anthropic" | "openai" | "gemini" | ...
#   ~/.bigide/active-model     → "opus" | "sonnet" | "gpt-5.1" | "gemini-2.5-pro" | ...
#   ~/.bigide/proxy/           → config YAML, PID, log del proxy LiteLLM
#   ~/.bigide/runners/<id>/    → cartella con settings.json (solo per runner custom)

RUNNERS_DIR="$BIGIDE_HOME/runners"
ACTIVE_RUNNER_FILE="$BIGIDE_HOME/active-runner"
ACTIVE_MODEL_FILE="$BIGIDE_HOME/active-model"

# ── OAuth helper generico ───────────────────────────────────────────────────────

_run_oauth() {
  local provider="$1" command="$2"
  local script="$BIGIDE_REPO_ROOT/config/scripts/oauth-${provider}.mjs"
  if [[ ! -f "$script" ]]; then
    log "ERROR" "Script OAuth non trovato: $script"
    return 1
  fi
  node "$script" "$command"
}

# ── OAuth shortcuts ──────────────────────────────────────────────────────────────
claude_oauth_login()   { _run_oauth claude login; }
claude_oauth_refresh() { _run_oauth claude refresh; }
claude_oauth_ensure()  { _run_oauth claude ensure; }
claude_oauth_status()  { _run_oauth claude status; }

openai_oauth_login()   { _run_oauth openai login; }
openai_oauth_refresh() { _run_oauth openai refresh; }
openai_oauth_ensure()  { _run_oauth openai ensure; }
openai_oauth_status()  { _run_oauth openai status; }

gemini_oauth_login()   { _run_oauth gemini login; }
gemini_oauth_refresh() { _run_oauth gemini refresh; }
gemini_oauth_ensure()  { _run_oauth gemini ensure; }
gemini_oauth_status()  { _run_oauth gemini status; }

# ── Runner helpers ───────────────────────────────────────────────────────────────

get_active_runner() {
  if [[ -f "$ACTIVE_RUNNER_FILE" ]]; then
    cat "$ACTIVE_RUNNER_FILE" 2>/dev/null
  else
    echo "anthropic"
  fi
}

get_active_model() {
  if [[ -f "$ACTIVE_MODEL_FILE" ]]; then
    cat "$ACTIVE_MODEL_FILE" 2>/dev/null
  else
    echo "sonnet"
  fi
}

# Lista runner custom configurati (esclude anthropic che è nativo)
list_custom_runners() {
  [[ -d "$RUNNERS_DIR" ]] || return 0
  for dir in "$RUNNERS_DIR"/*/; do
    [[ -f "${dir}settings.json" ]] || continue
    basename "$dir"
  done
}

# ── MCP setup ────────────────────────────────────────────────────────────────────

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

# ── Launch ──────────────────────────────────────────────────────────────────────

launch_claude() {
  local claude_extra="${*:-}"
  local claude_flags="--dangerously-skip-permissions"
  [[ -n "$claude_extra" ]] && claude_flags="$claude_flags $claude_extra"

  local runner model
  runner="$(get_active_runner)"
  model="$(get_active_model)"

  log "INFO" "Runner: $runner | Modello: $model"

  if [[ "$runner" == "anthropic" ]]; then
    # ── Anthropic nativo: usa --model, auth via ~/.claude ──
    # Ferma proxy se era attivo da un runner precedente
    proxy_stop 2>/dev/null || true

    claude_oauth_ensure 2>/dev/null || true

    # MCP nel config dir standard
    _ensure_mcp_registered "$HOME/.claude"

    log "INFO" "Avvio Claude (Anthropic) — modello: $model"
    exec claude --model "$model" $claude_flags

  elif [[ "$runner" == "openai" || "$runner" == "gemini" ]]; then
    # ── Provider esterno: LiteLLM proxy traduce Anthropic → OpenAI/Gemini ──
    if [[ "$runner" == "openai" ]]; then
      openai_oauth_ensure 2>/dev/null || true
    fi

    # Avvia/verifica proxy LiteLLM
    proxy_ensure "$runner" "$model" || {
      log "ERROR" "Impossibile avviare LiteLLM proxy per $runner/$model"
      exit 1
    }

    # MCP nel config dir standard
    _ensure_mcp_registered "$HOME/.claude"

    log "INFO" "Avvio Claude — runner: $runner, modello: $model (via LiteLLM proxy)"
    exec env \
      ANTHROPIC_BASE_URL="http://${PROXY_HOST:-127.0.0.1}:${PROXY_PORT:-4000}" \
      ANTHROPIC_API_KEY="$PROXY_MASTER_KEY" \
      claude --model "$model" $claude_flags

  else
    # ── Runner custom: usa CLAUDE_CONFIG_DIR ──
    local runner_dir="$RUNNERS_DIR/$runner"

    if [[ ! -d "$runner_dir" || ! -f "$runner_dir/settings.json" ]]; then
      log "WARN" "Runner '$runner' non configurato ($runner_dir), fallback Anthropic"
      exec claude --model sonnet $claude_flags
    fi

    # MCP nel runner dir
    _ensure_mcp_registered "$runner_dir"

    log "INFO" "Avvio Claude — runner: $runner (CLAUDE_CONFIG_DIR=$runner_dir)"
    export CLAUDE_CONFIG_DIR="$runner_dir"
    exec claude $claude_flags
  fi
}

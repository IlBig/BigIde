#!/usr/bin/env bash
set -euo pipefail

# ── BigIDE Runner: gestione profili multi-provider per Claude Code ──────────
#
# Approccio:
#   Anthropic (nativo) → claude --model <alias>  (auth via ~/.claude)
#   Altri provider      → CLAUDE_CONFIG_DIR=<runner_dir> claude
#                         settings.json con ANTHROPIC_BASE_URL, ANTHROPIC_API_KEY, ANTHROPIC_MODEL
#
# Struttura:
#   ~/.bigide/active-runner    → "anthropic" | "kimi" | "openai" | ...
#   ~/.bigide/active-model     → "opus" | "sonnet" | "kimi-k2.5" | ...
#   ~/.bigide/runners/<id>/    → cartella con settings.json (solo per runner non-Anthropic)

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
    claude_oauth_ensure 2>/dev/null || true

    # MCP nel config dir standard
    _ensure_mcp_registered "$HOME/.claude"

    log "INFO" "Avvio Claude (Anthropic) — modello: $model"
    exec claude --model "$model" $claude_flags

  elif [[ "$runner" == "openai" || "$runner" == "gemini" ]]; then
    # ── Provider esterno: tutto autocontenuto in ~/.bigide/runners/<id> ──
    local runner_dir="$RUNNERS_DIR/$runner"
    mkdir -p "$runner_dir"

    local token="" base_url=""
    if [[ "$runner" == "openai" ]]; then
      openai_oauth_ensure 2>/dev/null || true
      base_url="https://api.openai.com/v1"
      token="$(jq -r '.tokens.access_token // empty' "$HOME/.codex/auth.json" 2>/dev/null)" || true
    else
      base_url="https://generativelanguage.googleapis.com/v1beta/openai/"
      local gemini_key_file="$BIGIDE_HOME/gemini-api-key"
      if [[ -n "${GEMINI_API_KEY:-}" ]]; then
        token="$GEMINI_API_KEY"
      elif [[ -n "${GOOGLE_API_KEY:-}" ]]; then
        token="$GOOGLE_API_KEY"
      elif [[ -f "$gemini_key_file" ]]; then
        token="$(cat "$gemini_key_file" 2>/dev/null)" || true
      fi
    fi

    # settings.json autocontenuto (non legge da ~/.claude)
    cat > "$runner_dir/settings.json" << JSON
{
  "env": {
    "ANTHROPIC_BASE_URL": "${base_url}",
    "ANTHROPIC_API_KEY": "${token}",
    "ANTHROPIC_MODEL": "${model}"
  },
  "skipDangerousModePermissionPrompt": true
}
JSON

    _ensure_mcp_registered "$runner_dir"

    log "INFO" "Avvio Claude — runner: $runner, modello: $model"
    export CLAUDE_CONFIG_DIR="$runner_dir"
    exec claude $claude_flags

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

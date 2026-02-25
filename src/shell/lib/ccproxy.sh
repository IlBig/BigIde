#!/usr/bin/env bash
set -euo pipefail

# ── ccproxy: proxy Python per Claude Code → LiteLLM → multi-provider ──────────
# Pacchetto: claude-ccproxy (PyPI), installato via uv/pip
# OAuth scripts (Node.js standalone, zero dipendenze):
#   config/scripts/oauth-openai.mjs  → ~/.codex/auth.json
#   config/scripts/oauth-claude.mjs  → ~/.claude/.credentials.json
#   config/scripts/oauth-gemini.mjs  → ~/.gemini/auth.json

CCPROXY_CONFIG_DIR="$HOME/.ccproxy"

ccproxy_bin_path() {
  if command -v ccproxy >/dev/null 2>&1; then
    command -v ccproxy
    return 0
  fi
  return 1
}

install_ccproxy() {
  log "INFO" "Installazione ccproxy (Python)..."

  # Strategia 1: uv tool install (raccomandato)
  if command -v uv >/dev/null 2>&1; then
    if uv tool install claude-ccproxy --with 'litellm[proxy]' 2>&1; then
      log "INFO" "ccproxy installato via uv"
      return 0
    fi
  fi

  # Strategia 2: pipx
  if command -v pipx >/dev/null 2>&1; then
    if pipx install claude-ccproxy --pip-args='litellm[proxy]' 2>&1; then
      log "INFO" "ccproxy installato via pipx"
      return 0
    fi
  fi

  # Strategia 3: pip diretto
  if command -v pip3 >/dev/null 2>&1; then
    if pip3 install --user claude-ccproxy 'litellm[proxy]' 2>&1; then
      log "INFO" "ccproxy installato via pip3"
      return 0
    fi
  fi

  log "WARN" "Installazione ccproxy non riuscita. Installa manualmente: uv tool install claude-ccproxy --with 'litellm[proxy]'"
  return 1
}

ensure_ccproxy() {
  if ccproxy_bin_path >/dev/null 2>&1; then
    return 0
  fi
  install_ccproxy || return 1
  ccproxy_bin_path >/dev/null 2>&1
}

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

# ── OAuth OpenAI ────────────────────────────────────────────────────────────────
openai_oauth_login()   { _run_oauth openai login; }
openai_oauth_refresh() { _run_oauth openai refresh; }
openai_oauth_ensure()  { _run_oauth openai ensure; }
openai_oauth_status()  { _run_oauth openai status; }

# ── OAuth Claude (Anthropic) ────────────────────────────────────────────────────
claude_oauth_login()   { _run_oauth claude login; }
claude_oauth_refresh() { _run_oauth claude refresh; }
claude_oauth_ensure()  { _run_oauth claude ensure; }
claude_oauth_status()  { _run_oauth claude status; }

# ── OAuth Gemini (Google) ───────────────────────────────────────────────────────
gemini_oauth_login()   { _run_oauth gemini login; }
gemini_oauth_refresh() { _run_oauth gemini refresh; }
gemini_oauth_ensure()  { _run_oauth gemini ensure; }
gemini_oauth_status()  { _run_oauth gemini status; }

# ── Generazione config ccproxy ──────────────────────────────────────────────────

generate_ccproxy_config() {
  # Se config esiste già (generata dal runner-selector), non sovrascrivere
  if [[ -f "$CCPROXY_CONFIG_DIR/config.yaml" && -f "$CCPROXY_CONFIG_DIR/ccproxy.yaml" ]]; then
    log "INFO" "Configurazione ccproxy già presente in $CCPROXY_CONFIG_DIR"
    return 0
  fi

  mkdir -p "$CCPROXY_CONFIG_DIR"

  # ccproxy.yaml — routing + credenziali OAuth
  cat > "$CCPROXY_CONFIG_DIR/ccproxy.yaml" << 'YAML'
ccproxy:
  debug: false
  oat_sources:
    anthropic: "jq -r '.claudeAiOauth.accessToken' ~/.claude/.credentials.json"
    openai: "jq -r '.tokens.access_token' ~/.codex/auth.json"
    google: "jq -r '.tokens.access_token' ~/.gemini/auth.json"
  hooks:
    - ccproxy.hooks.rule_evaluator
    - ccproxy.hooks.model_router
    - ccproxy.hooks.forward_oauth
  rules:
    - name: background
      rule: ccproxy.rules.MatchModelRule
      params:
        - model_name: claude-haiku-4-5-20251001
    - name: think
      rule: ccproxy.rules.ThinkingRule

litellm:
  host: 127.0.0.1
  port: 4000
  num_workers: 4
YAML

  # config.yaml — deployment modelli (default Anthropic)
  cat > "$CCPROXY_CONFIG_DIR/config.yaml" << 'YAML'
model_list:
  - model_name: default
    litellm_params:
      model: anthropic/claude-sonnet-4-5-20250929
      api_base: https://api.anthropic.com

  - model_name: think
    litellm_params:
      model: anthropic/claude-opus-4-5-20251101
      api_base: https://api.anthropic.com

  - model_name: background
    litellm_params:
      model: anthropic/claude-haiku-4-5-20251001
      api_base: https://api.anthropic.com

litellm_settings:
  callbacks:
    - ccproxy.handler

general_settings:
  forward_client_headers_to_llm_api: true
YAML

  # Salva modello attivo di default
  echo "anthropic/claude-sonnet-4-5-20250929" > "$CCPROXY_CONFIG_DIR/active-model"

  log "INFO" "Configurazione ccproxy generata in $CCPROXY_CONFIG_DIR"
}

# ── Launch ──────────────────────────────────────────────────────────────────────

launch_claude_with_proxy() {
  local claude_extra="${*:-}"
  local proxy_mode
  proxy_mode="$(jq -r '.ccproxy.mode // "auto"' "$BIGIDE_HOME/config.json" 2>/dev/null || echo auto)"

  local claude_flags="--dangerously-skip-permissions"
  [[ -n "$claude_extra" ]] && claude_flags="$claude_flags $claude_extra"

  if [[ "$proxy_mode" == "disabled" ]]; then
    exec claude $claude_flags
  fi

  # In modalità auto: usa ccproxy solo se già installato
  if ccproxy_bin_path >/dev/null 2>&1; then
    local ccproxy_path
    ccproxy_path="$(ccproxy_bin_path)"

    # Genera config se mancante
    [[ -f "$CCPROXY_CONFIG_DIR/ccproxy.yaml" ]] || generate_ccproxy_config

    # Assicura token validi (refresh silenzioso per tutti i provider)
    claude_oauth_ensure 2>/dev/null || true
    openai_oauth_ensure 2>/dev/null || true
    gemini_oauth_ensure 2>/dev/null || true

    # Tenta avvio con ccproxy
    if "$ccproxy_path" run --help >/dev/null 2>&1; then
      exec "$ccproxy_path" run claude $claude_flags
    fi

    if "$ccproxy_path" start --help >/dev/null 2>&1; then
      "$ccproxy_path" start >/dev/null 2>&1 || true
      exec claude $claude_flags
    fi
  fi

  # ccproxy non installato: Claude diretto (silenzioso)
  exec claude $claude_flags
}

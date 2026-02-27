#!/usr/bin/env bash
set -euo pipefail

# ── BigIDE LiteLLM Proxy: traduzione Anthropic Messages API → OpenAI/Gemini ──
#
# Claude Code invia richieste in formato Anthropic (/v1/messages).
# LiteLLM accetta quel formato e lo traduce nel formato nativo del provider.
# Il proxy gira su 127.0.0.1:4000, accessibile solo localmente.

PROXY_DIR="$BIGIDE_HOME/proxy"
PROXY_PID_FILE="$PROXY_DIR/proxy.pid"
PROXY_CONFIG="$PROXY_DIR/config.yaml"
PROXY_LOG="$PROXY_DIR/proxy.log"
PROXY_PORT=4000
PROXY_HOST="127.0.0.1"
PROXY_MASTER_KEY="sk-bigide-local"

# ── Helpers ────────────────────────────────────────────────────────────────────

_proxy_pid() {
  [[ -f "$PROXY_PID_FILE" ]] && cat "$PROXY_PID_FILE" 2>/dev/null || echo ""
}

_proxy_running() {
  local pid
  pid="$(_proxy_pid)"
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

_litellm_bin() {
  # Cerca litellm nel PATH o nelle posizioni comuni di uv/pip
  if command -v litellm >/dev/null 2>&1; then
    command -v litellm
    return
  fi
  for candidate in "$HOME/.local/bin/litellm" "$HOME/.local/pipx/venvs/litellm/bin/litellm"; do
    if [[ -x "$candidate" ]]; then
      echo "$candidate"
      return
    fi
  done
  return 1
}

# ── Token retrieval ────────────────────────────────────────────────────────────

_get_openai_token() {
  jq -r '.tokens.access_token // empty' "$HOME/.codex/auth.json" 2>/dev/null || true
}

_get_gemini_token() {
  if [[ -n "${GEMINI_API_KEY:-}" ]]; then
    echo "$GEMINI_API_KEY"
  elif [[ -n "${GOOGLE_API_KEY:-}" ]]; then
    echo "$GOOGLE_API_KEY"
  elif [[ -f "$BIGIDE_HOME/gemini-api-key" ]]; then
    cat "$BIGIDE_HOME/gemini-api-key" 2>/dev/null
  fi
}

# ── Config generation ──────────────────────────────────────────────────────────

_generate_proxy_config() {
  local provider="$1" model="$2"
  local token="" litellm_model=""

  if [[ "$provider" == "openai" ]]; then
    token="$(_get_openai_token)"
    litellm_model="openai/${model}"
  elif [[ "$provider" == "gemini" ]]; then
    token="$(_get_gemini_token)"
    litellm_model="gemini/${model}"
  else
    log "ERROR" "Provider proxy non supportato: $provider"
    return 1
  fi

  if [[ -z "$token" ]]; then
    log "ERROR" "Nessun token trovato per provider: $provider"
    return 1
  fi

  mkdir -p "$PROXY_DIR"

  # Claude Code manda richieste con il model name selezionato MA anche con
  # modelli interni (claude-haiku, claude-sonnet, claude-opus) per sub-task.
  # Duplichiamo le entry in model_list per catturarli tutti.
  cat > "$PROXY_CONFIG" <<YAML
model_list:
  - model_name: "${model}"
    litellm_params:
      model: "${litellm_model}"
      api_key: "${token}"
    model_info:
      mode: chat
  - model_name: "claude-haiku-4-5-20251001"
    litellm_params:
      model: "${litellm_model}"
      api_key: "${token}"
    model_info:
      mode: chat
  - model_name: "claude-sonnet-4-6-20250514"
    litellm_params:
      model: "${litellm_model}"
      api_key: "${token}"
    model_info:
      mode: chat
  - model_name: "claude-opus-4-6-20250610"
    litellm_params:
      model: "${litellm_model}"
      api_key: "${token}"
    model_info:
      mode: chat

litellm_settings:
  drop_params: true
  num_retries: 3
  request_timeout: 120

general_settings:
  master_key: "${PROXY_MASTER_KEY}"
YAML

  # Salva provider/model corrente per confronto
  echo "${provider}:${model}" > "$PROXY_DIR/active-config"
}

# ── Lifecycle ──────────────────────────────────────────────────────────────────

proxy_start() {
  local provider="$1" model="$2"

  local litellm_bin
  litellm_bin="$(_litellm_bin)" || {
    log "ERROR" "LiteLLM non trovato. Esegui: uv tool install 'litellm[proxy]'"
    return 1
  }

  _generate_proxy_config "$provider" "$model" || return 1

  log "INFO" "Avvio LiteLLM proxy (${provider}/${model}) su ${PROXY_HOST}:${PROXY_PORT}"

  # Avvia in background, log in file
  # LITELLM_USE_RESPONSES_API=false: forza Chat Completions API per OpenAI
  # (il token Codex OAuth non ha scope api.responses.write per la Responses API)
  nohup env LITELLM_USE_RESPONSES_API=false "$litellm_bin" \
    --config "$PROXY_CONFIG" \
    --host "$PROXY_HOST" \
    --port "$PROXY_PORT" \
    > "$PROXY_LOG" 2>&1 &

  local pid=$!
  echo "$pid" > "$PROXY_PID_FILE"
  log "INFO" "LiteLLM proxy avviato (PID: $pid)"

  # Attendi che il proxy sia pronto (max 15s)
  local attempts=0
  while (( attempts < 30 )); do
    if proxy_health 2>/dev/null; then
      log "INFO" "LiteLLM proxy pronto"
      return 0
    fi
    sleep 0.5
    (( attempts++ ))
  done

  log "WARN" "LiteLLM proxy avviato ma health check non risponde ancora"
  return 0
}

proxy_stop() {
  local pid
  pid="$(_proxy_pid)"
  if [[ -n "$pid" ]]; then
    if kill -0 "$pid" 2>/dev/null; then
      log "INFO" "Fermo LiteLLM proxy (PID: $pid)"
      kill "$pid" 2>/dev/null || true
      # Attendi termine graceful (max 5s)
      local i=0
      while (( i < 10 )) && kill -0 "$pid" 2>/dev/null; do
        sleep 0.5
        (( i++ ))
      done
      # Force kill se ancora vivo
      kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null || true
    fi
    rm -f "$PROXY_PID_FILE"
  fi
}

proxy_health() {
  curl -sf --max-time 2 \
    -H "Authorization: Bearer ${PROXY_MASTER_KEY}" \
    "http://${PROXY_HOST}:${PROXY_PORT}/health" >/dev/null 2>&1
}

proxy_ensure() {
  local provider="$1" model="$2"
  local desired="${provider}:${model}"
  local current=""

  [[ -f "$PROXY_DIR/active-config" ]] && current="$(cat "$PROXY_DIR/active-config" 2>/dev/null)" || true

  if _proxy_running && [[ "$current" == "$desired" ]]; then
    # Proxy gia' in esecuzione con la config corretta
    log "INFO" "LiteLLM proxy gia' attivo per ${provider}/${model}"
    return 0
  fi

  # Stop se in esecuzione con config diversa
  if _proxy_running; then
    log "INFO" "Riavvio proxy: config cambiata ($current -> $desired)"
    proxy_stop
  fi

  proxy_start "$provider" "$model"
}

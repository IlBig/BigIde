#!/usr/bin/env bash
set -euo pipefail

ccproxy_bin_path() {
  if command -v ccproxy >/dev/null 2>&1; then
    command -v ccproxy
    return 0
  fi

  if [[ -x "$BIGIDE_HOME/tools/ccproxy/ccproxy" ]]; then
    echo "$BIGIDE_HOME/tools/ccproxy/ccproxy"
    return 0
  fi

  return 1
}

install_ccproxy() {
  mkdir -p "$BIGIDE_HOME/tools"

  log "INFO" "Tentativo installazione ccproxy (trasparente)"

  if command -v brew >/dev/null 2>&1; then
    if brew install ccproxy >/dev/null 2>&1; then
      log "INFO" "ccproxy installato via brew"
      return 0
    fi
  fi

  if command -v go >/dev/null 2>&1; then
    if GOBIN="$BIGIDE_HOME/tools" go install github.com/starbased-co/ccproxy@latest >/dev/null 2>&1; then
      log "INFO" "ccproxy installato via go install"
      return 0
    fi
  fi

  if command -v git >/dev/null 2>&1 && command -v make >/dev/null 2>&1; then
    local target_dir="$BIGIDE_HOME/tools/ccproxy-src"
    rm -rf "$target_dir"
    if git clone https://github.com/starbased-co/ccproxy "$target_dir" >/dev/null 2>&1; then
      if (cd "$target_dir" && make >/dev/null 2>&1); then
        if [[ -x "$target_dir/ccproxy" ]]; then
          cp "$target_dir/ccproxy" "$BIGIDE_HOME/tools/ccproxy"
          chmod +x "$BIGIDE_HOME/tools/ccproxy"
          log "INFO" "ccproxy installato via sorgenti"
          return 0
        fi
      fi
    fi
  fi

  log "WARN" "Installazione automatica ccproxy non riuscita: fallback su Claude diretto"
  return 1
}

ensure_ccproxy() {
  if ccproxy_bin_path >/dev/null 2>&1; then
    return 0
  fi

  install_ccproxy || return 1
  ccproxy_bin_path >/dev/null 2>&1
}

launch_claude_with_proxy() {
  local ccproxy_path
  local proxy_mode

  proxy_mode="$(jq -r '.ccproxy.mode // "auto"' "$BIGIDE_HOME/config.json" 2>/dev/null || echo auto)"

  if [[ "$proxy_mode" == "disabled" ]]; then
    exec claude
  fi

  # In modalità auto: usa ccproxy solo se già installato, senza tentare install
  # Per installare ccproxy usa: bigide --install-ccproxy
  if ccproxy_bin_path >/dev/null 2>&1; then
    ccproxy_path="$(ccproxy_bin_path)"

    if "$ccproxy_path" --help 2>&1 | grep -q " claude"; then
      exec "$ccproxy_path" claude
    fi

    if "$ccproxy_path" run --help >/dev/null 2>&1; then
      exec "$ccproxy_path" run claude
    fi

    if "$ccproxy_path" start --help >/dev/null 2>&1; then
      "$ccproxy_path" start >/dev/null 2>&1 || true
      exec claude
    fi
  fi

  # ccproxy non installato o non riconosciuto: Claude diretto (silenzioso)
  exec claude
}

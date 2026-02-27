#!/usr/bin/env bash
# BigIDE — Ferma il proxy LiteLLM (usato da tmux session-closed hook)
PROXY_PID_FILE="${HOME}/.bigide/proxy/proxy.pid"

if [[ -f "$PROXY_PID_FILE" ]]; then
  pid="$(cat "$PROXY_PID_FILE" 2>/dev/null)" || true
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
    sleep 1
    kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null || true
  fi
  rm -f "$PROXY_PID_FILE"
fi

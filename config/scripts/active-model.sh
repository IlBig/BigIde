#!/usr/bin/env bash
# Legge ~/.bigide/active-runner e formatta il nome provider per la status bar tmux.
# Output: " (claude)" | " (codex)" | " (gemini)"
BIGIDE_HOME="${BIGIDE_HOME:-$HOME/.bigide}"

runner="$(cat "$BIGIDE_HOME/active-runner" 2>/dev/null)" || exit 0
[[ -z "$runner" ]] && exit 0

case "$runner" in
  anthropic) echo " (claude)" ;;
  openai)    echo " (codex)"  ;;
  gemini)    echo " (gemini)" ;;
  *)         echo " ($runner)" ;;
esac

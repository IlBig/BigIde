#!/usr/bin/env bash
# Legge ~/.bigide/active-runner + active-model e formatta per la status bar tmux.
# Output: " (opus)" oppure " (kimi-k2.5)" oppure "" (vuoto se nessun modello)
BIGIDE_HOME="${BIGIDE_HOME:-$HOME/.bigide}"

runner="$(cat "$BIGIDE_HOME/active-runner" 2>/dev/null)" || exit 0
model="$(cat "$BIGIDE_HOME/active-model" 2>/dev/null)" || exit 0
[[ -z "$model" ]] && exit 0

if [[ "$runner" == "anthropic" ]]; then
  echo " ($model)"
else
  echo " ($runner: $model)"
fi

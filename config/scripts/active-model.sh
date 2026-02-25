#!/usr/bin/env bash
# Legge ~/.ccproxy/active-model e formatta per la status bar tmux.
# Output: " (claude-sonnet-4-5)" oppure "" (vuoto se nessun modello)
FILE="$HOME/.ccproxy/active-model"
[[ -f "$FILE" ]] || exit 0
raw="$(cat "$FILE" 2>/dev/null)"
[[ -z "$raw" ]] && exit 0

# Rimuovi prefisso provider (anthropic/, openai/, vertex_ai/)
name="${raw##*/}"
# Rimuovi suffisso data (-20251101, -20250929, ecc.)
name="$(echo "$name" | sed 's/-[0-9]\{8\}$//')"

[[ -z "$name" ]] && exit 0
echo " ($name)"

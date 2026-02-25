#!/usr/bin/env bash
# Legge ~/.ccproxy/active-model e formatta un nome corto per la status bar.
# Output: es. "claude-sonnet-4-5" / "o3" / "gemini-2.5-pro" / "" (vuoto se nessuno)
FILE="$HOME/.ccproxy/active-model"
[[ -f "$FILE" ]] || exit 0
raw="$(cat "$FILE" 2>/dev/null)"
[[ -z "$raw" ]] && exit 0

# Rimuovi prefisso provider (anthropic/, openai/, vertex_ai/)
name="${raw##*/}"
# Rimuovi suffisso data (-20251101, -20250929, ecc.)
name="$(echo "$name" | sed 's/-[0-9]\{8\}$//')"

echo "$name"

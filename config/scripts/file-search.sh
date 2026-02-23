#!/usr/bin/env bash
# BigIDE — Ricerca file fuzzy con fzf
# Seleziona un file → lo apre nella preview di neo-tree
# Chiamato da tmux popup (prefix + Spazio)
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

RESULT_FILE="/tmp/bigide-fzf-result"
rm -f "$RESULT_FILE"

selected=$(find . \
  -not -path '*/.git/*' \
  -not -path '*/node_modules/*' \
  -not -path '*/__pycache__/*' \
  -not -path '*/.next/*' \
  -not -path '*/.nuxt/*' \
  -not -path '*/build/*' \
  -not -path '*/dist/*' \
  -not -path '*/.cache/*' \
  -not -path '*/.tmp/*' \
  -not -path '*/vendor/*' \
  -not -path '*/Pods/*' \
  -not -path '*/.build/*' \
  -not -path '*/target/*' \
  -not -name '.DS_Store' \
  -type f \
  2>/dev/null | sed 's|^\./||' | sort | \
  fzf \
    --height=100% \
    --layout=reverse \
    --border=rounded \
    --prompt="  " \
    --pointer="▶" \
    --marker="●" \
    --header="Cerca file — Esc chiudi" \
    --preview='cat -n {}' \
    --preview-window='right:50%:border-left' \
    --color='bg+:#2e3c64,fg+:#c0caf5,hl:#ff9e64,hl+:#ff9e64,border:#3b4261,header:#565f89,prompt:#7aa2f7,pointer:#7aa2f7' \
) || true

if [[ -n "$selected" ]]; then
  echo "$(pwd)/$selected" > "$RESULT_FILE"
  # Notifica neovim (pane 0) di aprire il file selezionato
  tmux send-keys -t ":.0" Escape
  tmux send-keys -t ":.0" ":lua BigideOpenSearch()" Enter
fi

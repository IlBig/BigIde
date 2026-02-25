#!/usr/bin/env bash
# BigIDE — Git branch switch con fzf
# Chiamato da tmux popup (prefix + g b)
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Verifica repo git
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  printf '\033[38;2;255;158;100m  Non è un repository git.\033[0m\n'
  sleep 1.5
  exit 0
fi

CURRENT="$(git branch --show-current 2>/dev/null || echo "")"

FZF_COLORS='bg:#1a1b26,bg+:#2e3c64,fg:#a9b1d6,fg+:#c0caf5,hl:#ff9e64,hl+:#ff9e64,border:#3b4261,header:#565f89,prompt:#7aa2f7,pointer:#7aa2f7,marker:#9ece6a,info:#565f89'

selected=$(git for-each-ref --format='%(refname:short)' refs/heads | \
  fzf \
    --height=100% \
    --layout=reverse \
    --border=rounded \
    --prompt=" Branch  " \
    --pointer="▶" \
    --marker="●" \
    --header="  Ramo corrente: ${CURRENT:-detached}  │  Enter seleziona  │  Esc annulla" \
    --color="$FZF_COLORS" \
    --no-multi \
    --ansi \
) || exit 0

if [[ -n "$selected" && "$selected" != "$CURRENT" ]]; then
  git checkout "$selected" 2>&1
  printf '\n\033[38;2;158;206;106m  ✔ Passato a: %s\033[0m\n' "$selected"
  # Refresh neo-tree nel pane filetree (pane con @bigide_pane_type=yazi)
  TREE_PANE="$(tmux list-panes -F '#{pane_id} #{@bigide_pane_type}' 2>/dev/null | awk '$2=="yazi"{print $1}')"
  if [[ -n "$TREE_PANE" ]]; then
    tmux send-keys -t "$TREE_PANE" Escape
    tmux send-keys -t "$TREE_PANE" ":Neotree action=focus reveal=true" Enter
  fi
  sleep 0.5
fi

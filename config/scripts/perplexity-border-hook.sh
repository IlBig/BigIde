#!/usr/bin/env bash
# Hook tmux after-select-pane — bordo bianco SOLO sul pane Perplexity
PERP_FILE="$HOME/.bigide/perplexity/.pane_id"
[[ -f "$PERP_FILE" ]] || exit 0

PERP=$(cat "$PERP_FILE")
ACTIVE=$(tmux display-message -p '#{pane_id}')

if [[ "$ACTIVE" = "$PERP" ]]; then
  tmux set-option -w pane-active-border-style "fg=white,bg=#1e2030"
else
  tmux set-option -w pane-active-border-style "fg=#3b4261,bg=#1e2030"
fi

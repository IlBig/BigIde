#!/usr/bin/env bash
# BigIDE — Toggle pannello Perplexity
# prefix+p: apre split 50/50 con Claude Code, chiude se già aperto

BIGIDE_REPO_ROOT="${BIGIDE_REPO_ROOT:-__BIGIDE_REPO_ROOT__}"
TOKENS_FILE="$HOME/.bigide/perplexity/tokens.env"

# Cerca il pannello Perplexity per titolo/env nella sessione corrente
_find_perplexity_pane() {
  tmux list-panes -a -F '#{pane_id} #{pane_title}' 2>/dev/null \
    | grep -i "perplexity" | awk '{print $1}' | head -1
}

_find_perplexity_pane_by_pid() {
  # Cerca per variabile d'ambiente BIGIDE_PANE_TYPE=perplexity
  local session="${TMUX_SESSION:-$(tmux display-message -p '#{session_name}' 2>/dev/null)}"
  tmux list-panes -t "$session" -F '#{pane_id}' 2>/dev/null | while read pane_id; do
    if tmux show-environment -t "$pane_id" BIGIDE_PANE_TYPE 2>/dev/null | grep -q "perplexity"; then
      echo "$pane_id"
      return
    fi
  done
}

SESSION=$(tmux display-message -p '#{session_name}')
PERP_PANE=$(tmux list-panes -t "$SESSION" -F '#{pane_id} #{@bigide_pane_type}' 2>/dev/null \
  | awk '$2=="perplexity"{print $1}' | head -1)

if [[ -n "$PERP_PANE" ]]; then
  # Pannello esiste → chiudilo
  tmux kill-pane -t "$PERP_PANE"
else
  # Pannello non esiste → split verticale 50% del pane Claude (pane 2 = right_top)
  CLAUDE_PANE=$(tmux list-panes -t "$SESSION" -F '#{pane_id} #{@bigide_pane_type}' 2>/dev/null \
    | awk '$2=="claude"{print $1}' | head -1)

  # Fallback: pane indice 1 della finestra main (sempre Claude nel layout default)
  [[ -z "$CLAUDE_PANE" ]] && CLAUDE_PANE=$(tmux display-message -p -t "${SESSION}:0.1" '#{pane_id}' 2>/dev/null)
  [[ -z "$CLAUDE_PANE" ]] && CLAUDE_PANE=$(tmux display-message -p '#{pane_id}')

  NEW_PANE=$(tmux split-window -h -p 50 -t "$CLAUDE_PANE" -P -F '#{pane_id}')
  
  # Marca il nuovo pane come perplexity
  tmux set-option -t "$NEW_PANE" @bigide_pane_type "perplexity"
  
  # Avvia wrapper
  tmux send-keys -t "$NEW_PANE" \
    "BIGIDE_PANE_TYPE=perplexity bash \$HOME/.bigide/scripts/perplexity-wrapper.sh" C-m
fi

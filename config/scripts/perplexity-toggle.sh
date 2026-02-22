#!/usr/bin/env bash
# BigIDE — Toggle pannello Perplexity
# prefix+p: apre split 50/50 su Claude Code, chiude se già aperto

PANE_ID_FILE="$HOME/.bigide/perplexity/.pane_id"

# ── Cerca se il pannello Perplexity esiste già ────────────────────────────────
PERP_PANE=""
if [[ -f "$PANE_ID_FILE" ]]; then
  stored="$(cat "$PANE_ID_FILE")"
  # Verifica che il pane sia ancora vivo
  if tmux list-panes -a -F '#{pane_id}' 2>/dev/null | grep -qF "$stored"; then
    PERP_PANE="$stored"
  else
    rm -f "$PANE_ID_FILE"
  fi
fi

# ── Toggle ────────────────────────────────────────────────────────────────────
if [[ -n "$PERP_PANE" ]]; then
  tmux kill-pane -t "$PERP_PANE"
  rm -f "$PANE_ID_FILE"
else
  SESSION=$(tmux display-message -p '#{session_name}')

  # Trova Claude Code per tag (@bigide_pane_type claude, impostato con -p in layout.sh)
  CLAUDE_PANE=$(tmux list-panes -t "$SESSION" -F '#{pane_id} #{@bigide_pane_type}' 2>/dev/null \
    | awk '$2=="claude"{print $1}' | head -1)

  # Fallback: indice .1 = Claude nel layout default (yazi=.0, claude=.1)
  [[ -z "$CLAUDE_PANE" ]] && \
    CLAUDE_PANE=$(tmux display-message -p -t "${SESSION}:0.1" '#{pane_id}' 2>/dev/null)
  [[ -z "$CLAUDE_PANE" ]] && \
    CLAUDE_PANE=$(tmux display-message -p '#{pane_id}')

  NEW_PANE=$(tmux split-window -h -p 50 -t "$CLAUDE_PANE" -P -F '#{pane_id}')

  # Salva ID per il prossimo toggle
  mkdir -p "$(dirname "$PANE_ID_FILE")"
  echo "$NEW_PANE" > "$PANE_ID_FILE"

  tmux send-keys -t "$NEW_PANE" \
    "BIGIDE_PANE_TYPE=perplexity bash \$HOME/.bigide/scripts/perplexity-wrapper.sh" C-m
fi

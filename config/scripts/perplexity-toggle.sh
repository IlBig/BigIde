#!/usr/bin/env bash
# BigIDE — Toggle pannello Perplexity
# prefix+p: apre split 50/50 su Claude Code, chiude se già aperto

_L() { printf '%s [EVENT] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$HOME/.bigide/logs/bigide.log" 2>/dev/null || true; }

PANE_ID_FILE="$HOME/.bigide/perplexity/.pane_id"

# ── Cerca se il pannello Perplexity esiste già ────────────────────────────────
PERP_PANE=""
if [[ -f "$PANE_ID_FILE" ]]; then
  stored="$(cat "$PANE_ID_FILE")"
  # Verifica che il pane sia ancora vivo (scope alla sessione corrente)
  if tmux list-panes -s -F '#{pane_id}' 2>/dev/null | grep -qF "$stored"; then
    PERP_PANE="$stored"
  else
    rm -f "$PANE_ID_FILE"
  fi
fi

# ── Toggle ────────────────────────────────────────────────────────────────────
if [[ -n "$PERP_PANE" ]]; then
  _L "perplexity: OFF — kill pane $PERP_PANE"
  tmux kill-pane -t "$PERP_PANE"
  rm -f "$PANE_ID_FILE"
  # Rimuovi hook e ripristina bordo standard
  SESSION=$(tmux display-message -p '#{session_name}')
  tmux set-hook -u -t "$SESSION" after-select-pane 2>/dev/null || true
  tmux set-option -w pane-active-border-style "fg=#3b4261,bg=#1e2030"
else
  SESSION=$(tmux display-message -p '#{session_name}')

  # Trova Claude Code per tag nel window corrente
  CLAUDE_PANE=$(tmux list-panes -F '#{pane_id} #{@bigide_pane_type}' 2>/dev/null \
    | awk '$2=="claude"{print $1}' | head -1)

  # Fallback: cerca nella sessione
  [[ -z "$CLAUDE_PANE" ]] && \
    CLAUDE_PANE=$(tmux list-panes -t "$SESSION" -F '#{pane_id} #{@bigide_pane_type}' 2>/dev/null \
      | awk '$2=="claude"{print $1}' | head -1)
  [[ -z "$CLAUDE_PANE" ]] && \
    CLAUDE_PANE=$(tmux display-message -p '#{pane_id}')

  NEW_PANE=$(tmux split-window -h -p 50 -t "$CLAUDE_PANE" -P -F '#{pane_id}')
  _L "perplexity: ON — new pane $NEW_PANE split from claude $CLAUDE_PANE"

  # Salva ID per il prossimo toggle
  mkdir -p "$(dirname "$PANE_ID_FILE")"
  echo "$NEW_PANE" > "$PANE_ID_FILE"

  # Hook: bordo bianco solo quando il pane Perplexity è attivo
  tmux set-hook -t "$SESSION" after-select-pane \
    "run-shell 'bash $HOME/.bigide/scripts/perplexity-border-hook.sh'"
  # Applica subito (il nuovo pane è già attivo)
  tmux set-option -w pane-active-border-style "fg=white,bg=#1e2030"

  tmux send-keys -t "$NEW_PANE" \
    "BIGIDE_PANE_TYPE=perplexity bash \$HOME/.bigide/scripts/perplexity-wrapper.sh" C-m
fi

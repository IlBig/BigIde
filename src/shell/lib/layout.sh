#!/usr/bin/env bash
set -euo pipefail

load_layout_vars() {
  local layout_name="${1:-default}"
  local layout_file="$BIGIDE_HOME/layouts/${layout_name}.json"
  [[ -f "$layout_file" ]] || layout_file="$BIGIDE_HOME/layouts/default.json"
  [[ -f "$layout_file" ]] || die "Layout non trovato: $layout_file"

  yazi_width="$(jq -r '.panes[] | select(.id=="yazi") | .widthPercent' "$layout_file")"
  yazi_cols="$(jq -r '.panes[] | select(.id=="yazi") | .widthColumns // empty' "$layout_file")"
  claude_width="$(jq -r '.panes[] | select(.id=="claude") | .widthPercent' "$layout_file")"
  lower_height="$(jq -r '.panes[] | select(.id=="terminal") | .heightPercent' "$layout_file")"

  [[ "$yazi_width" =~ ^[0-9]+$ ]]   || die "Valore yazi width non valido"
  [[ "$claude_width" =~ ^[0-9]+$ ]]  || die "Valore claude width non valido"
  [[ "$lower_height" =~ ^[0-9]+$ ]]  || die "Valore lower height non valido"
}

apply_layout_resize() {
  local session_name="$1"
  local layout_name="${2:-default}"
  load_layout_vars "$layout_name"

  local tree_cols
  # Usa colonne assolute se definite, altrimenti percentuale
  if [[ -n "${yazi_cols:-}" && "$yazi_cols" =~ ^[0-9]+$ ]]; then
    tree_cols="$yazi_cols"
  else
    local total_cols
    total_cols=$(tmux display-message -p -t "${session_name}:0" "#{window_width}" 2>/dev/null) || return 0
    tree_cols=$(( total_cols * yazi_width / 100 ))
    [[ "$tree_cols" -lt 5 ]] && tree_cols=5
  fi

  # Pane 0 = file tree (pane più a sinistra nella finestra 0)
  tmux resize-pane -t "${session_name}:0.0" -x "$tree_cols" 2>/dev/null || true
}

create_layout() {
  local session_name="$1"
  local layout_name="${2:-default}"
  local top_pane_id left_top_id right_top_id terminal_pane_id

  load_layout_vars "$layout_name"

  tmux rename-window -t "$session_name":0 "main"

  top_pane_id="$(tmux display-message -p -t "$session_name":0.0 '#{pane_id}')"

  # Split orizzontale: sinistra (file-tree, stretta) | destra (claude+terminal, larga)
  right_top_id="$(tmux split-window -h -p "$claude_width" -t "$top_pane_id" -P -F '#{pane_id}')"
  left_top_id="$top_pane_id"

  # Split verticale destra: claude (alto) | terminal (basso)
  terminal_pane_id="$(tmux split-window -v -p "$lower_height" -t "$right_top_id" -P -F '#{pane_id}')"

  # Piccola pausa per assicurarsi che i pannelli siano pronti
  sleep 1

  # Avvio strumenti
  tmux send-keys -t "$left_top_id"      'clear; $HOME/.bigide/scripts/filetree.sh' C-m
  tmux send-keys -t "$right_top_id"     'clear; $HOME/.bigide/scripts/launch-claude.sh' C-m
  tmux send-keys -t "$terminal_pane_id" 'clear; zsh' C-m

  # Seleziona claude come pane attivo
  tmux select-pane -t "$right_top_id"
}

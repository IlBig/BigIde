#!/usr/bin/env bash
set -euo pipefail

load_layout_vars() {
  local layout_name="${1:-default}"
  local layout_file="$BIGIDE_HOME/layouts/${layout_name}.json"
  [[ -f "$layout_file" ]] || layout_file="$BIGIDE_HOME/layouts/default.json"
  [[ -f "$layout_file" ]] || die "Layout non trovato: $layout_file"

  yazi_width="$(jq -r '.panes[] | select(.id=="yazi") | .widthPercent' "$layout_file")"
  claude_width="$(jq -r '.panes[] | select(.id=="claude") | .widthPercent' "$layout_file")"
  lower_height="$(jq -r '.panes[] | select(.id=="terminal") | .heightPercent' "$layout_file")"
  git_bar_rows="$(jq -r '.gitBar.heightRows // 1' "$layout_file")"

  [[ "$yazi_width" =~ ^[0-9]+$ ]]   || die "Valore yazi width non valido"
  [[ "$claude_width" =~ ^[0-9]+$ ]]  || die "Valore claude width non valido"
  [[ "$lower_height" =~ ^[0-9]+$ ]]  || die "Valore lower height non valido"
  [[ "$git_bar_rows" =~ ^[0-9]+$ ]]  || die "Valore git bar rows non valido"
}

create_layout() {
  local session_name="$1"
  local layout_name="${2:-default}"
  local top_pane_id left_top_id right_top_id left_bottom_id terminal_pane_id git_bar_id

  load_layout_vars "$layout_name"

  tmux rename-window -t "$session_name":0 "main"

  top_pane_id="$(tmux display-message -p -t "$session_name":0.0 '#{pane_id}')"

  # Git bar: 1 riga in basso, larghezza piena
  git_bar_id="$(tmux split-window -v -l "$git_bar_rows" -t "$top_pane_id" -P -F '#{pane_id}')"

  # Split orizzontale: sinistra (yazi+monitor, stretta) | destra (claude+terminal, larga)
  right_top_id="$(tmux split-window -h -p "$claude_width" -t "$top_pane_id" -P -F '#{pane_id}')"
  left_top_id="$top_pane_id"

  # Split verticale sinistra: yazi (alto) | monitor (basso)
  left_bottom_id="$(tmux split-window -v -p "$lower_height" -t "$left_top_id" -P -F '#{pane_id}')"

  # Split verticale destra: claude (alto) | terminal (basso, larghezza piena)
  terminal_pane_id="$(tmux split-window -v -p "$lower_height" -t "$right_top_id" -P -F '#{pane_id}')"

  # Piccola pausa per assicurarsi che i pannelli siano pronti
  sleep 1

  # Avvio strumenti
  tmux send-keys -t "$left_top_id"    'clear; YAZI_CONFIG_HOME="$HOME/.bigide/yazi" yazi' C-m
  tmux send-keys -t "$right_top_id"   'clear; $HOME/.bigide/scripts/launch-claude.sh' C-m
  tmux send-keys -t "$left_bottom_id" 'clear; $HOME/.bigide/scripts/monitor.sh || zsh' C-m
  tmux send-keys -t "$terminal_pane_id" 'clear; zsh' C-m

  # Git bar: status git con ANSI diretto
  tmux send-keys -t "$git_bar_id" '$HOME/.bigide/scripts/git-bar.sh' C-m

  tmux select-pane -t "$right_top_id"
}

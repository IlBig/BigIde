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
  monitor_width="$(jq -r '.panes[] | select(.id=="monitor") | .widthPercent' "$layout_file")"
  log_width="$(jq -r '.panes[] | select(.id=="log") | .widthPercent' "$layout_file")"
  terminal_width="$(jq -r '.panes[] | select(.id=="terminal") | .widthPercent' "$layout_file")"
  git_bar_rows="$(jq -r '.gitBar.heightRows // 1' "$layout_file")"

  [[ "$yazi_width" =~ ^[0-9]+$ ]] || die "Valore yazi width non valido"
  [[ "$claude_width" =~ ^[0-9]+$ ]] || die "Valore claude width non valido"
  [[ "$lower_height" =~ ^[0-9]+$ ]] || die "Valore lower height non valido"
  [[ "$monitor_width" =~ ^[0-9]+$ ]] || die "Valore monitor width non valido"
  [[ "$log_width" =~ ^[0-9]+$ ]] || die "Valore log width non valido"
  [[ "$terminal_width" =~ ^[0-9]+$ ]] || die "Valore terminal width non valido"
  [[ "$git_bar_rows" =~ ^[0-9]+$ ]] || die "Valore git bar rows non valido"
}

create_layout() {
  local session_name="$1"
  local layout_name="${2:-default}"
  local top_pane_id left_top_id right_top_id left_bottom_id right_bottom_id log_pane_id terminal_pane_id git_bar_id
  local terminal_share_right

  load_layout_vars "$layout_name"

  tmux rename-window -t "$session_name":0 "main"

  top_pane_id="$(tmux display-message -p -t "$session_name":0.0 '#{pane_id}')"
  git_bar_id="$(tmux split-window -v -l "$git_bar_rows" -t "$top_pane_id" -P -F '#{pane_id}')"

  right_top_id="$(tmux split-window -h -p "$claude_width" -t "$top_pane_id" -P -F '#{pane_id}')"
  left_top_id="$top_pane_id"

  left_bottom_id="$(tmux split-window -v -p "$lower_height" -t "$left_top_id" -P -F '#{pane_id}')"
  right_bottom_id="$(tmux split-window -v -p "$lower_height" -t "$right_top_id" -P -F '#{pane_id}')"

  terminal_pane_id="$(tmux split-window -h -p "$terminal_share_right" -t "$right_bottom_id" -P -F '#{pane_id}')"
  log_pane_id="$right_bottom_id"

  tmux send-keys -t "$left_top_id" 'YAZI_CONFIG_HOME="$HOME/.bigide/yazi" yazi' C-m
  tmux send-keys -t "$right_top_id" '$HOME/.bigide/scripts/launch-claude.sh' C-m
  tmux send-keys -t "$left_bottom_id" '$HOME/.bigide/scripts/monitor.sh || bash' C-m
  tmux send-keys -t "$log_pane_id" 'tail -f /dev/null' C-m
  tmux send-keys -t "$terminal_pane_id" 'zsh' C-m
  tmux send-keys -t "$git_bar_id" 'gitmux -cfg "$HOME/.bigide/gitmux.conf" || bash' C-m

  tmux select-pane -t "$right_top_id"
}

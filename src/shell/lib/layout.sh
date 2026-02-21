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
  gitbar_lines="$(jq -r '.panes[] | select(.id=="gitbar") | .heightLines // empty' "$layout_file")"

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
  local full_pane gitbar_pane left_top_id right_top_id terminal_pane_id logs_pane_id

  load_layout_vars "$layout_name"

  tmux rename-window -t "$session_name":0 "main"

  full_pane="$(tmux display-message -p -t "$session_name":0.0 '#{pane_id}')"

  # 1. Taglia il git bar in fondo (2 righe, larghezza piena)
  local git_lines="${gitbar_lines:-2}"
  gitbar_pane="$(tmux split-window -v -l "$git_lines" -t "$full_pane" -P -F '#{pane_id}')"

  # 2. Nella zona superiore: split orizzontale → filetree (sx) | claude+terminal (dx)
  right_top_id="$(tmux split-window -h -p "$claude_width" -t "$full_pane" -P -F '#{pane_id}')"
  left_top_id="$full_pane"

  # 3. Split verticale colonna destra: claude (alto) | area-bassa (basso)
  terminal_pane_id="$(tmux split-window -v -p "$lower_height" -t "$right_top_id" -P -F '#{pane_id}')"

  # 4. Split orizzontale area-bassa: terminal (sx) | logs (dx)
  logs_pane_id="$(tmux split-window -h -p 50 -t "$terminal_pane_id" -P -F '#{pane_id}')"

  sleep 1

  # Avvio strumenti
  tmux send-keys -t "$left_top_id"      'clear; $HOME/.bigide/scripts/filetree.sh' C-m
  # Resize-trick: forza nvim a ridisegnare dopo startup (1col ±1 → evento resize → redraw completo)
  { sleep 5 && tmux resize-pane -t "${left_top_id}" -x 41 2>/dev/null && sleep 0.2 && tmux resize-pane -t "${left_top_id}" -x 40 2>/dev/null; } &
  tmux send-keys -t "$right_top_id"     'clear; $HOME/.bigide/scripts/launch-claude.sh' C-m
  tmux send-keys -t "$terminal_pane_id" 'clear; zsh' C-m
  tmux send-keys -t "$logs_pane_id"     'clear; zsh' C-m
  local project_path
  project_path="$(tmux display-message -p -t "${session_name}:0.0" '#{pane_current_path}')"
  tmux send-keys -t "$gitbar_pane" "while true; do bash \$HOME/.bigide/scripts/git-bar.sh '${project_path}' 2>/dev/null; sleep 2; done" C-m

  # Hook: usa pane ID (%N) stabili — gli indici (0.N) cambiano se si aggiungono pane manualmente
  # terminal/logs: ciascuno = (window_width - 40 filetree - 2 bordi) / 2
  tmux set-hook -t "$session_name" client-resized \
    "run-shell 'tw=\$(tmux display-message -p \"#{window_width}\"); half=\$(( (tw - 42) / 2 )); tmux resize-pane -t ${left_top_id} -x 40 2>/dev/null; tmux resize-pane -t ${gitbar_pane} -y 1 2>/dev/null; tmux resize-pane -t ${terminal_pane_id} -x \$half 2>/dev/null; true'"

  # Seleziona claude come pane attivo
  tmux select-pane -t "$right_top_id"
}

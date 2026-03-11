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
  local win_id
  win_id="$(tmux display-message -p -t "${session_name}:0" '#{window_id}' 2>/dev/null)" || return 0
  bash "$HOME/.bigide/scripts/resize-layout.sh" "$win_id" 2>/dev/null || true
}

create_layout() {
  local session_name="$1"
  local layout_name="${2:-default}"
  local full_pane gitbar_pane left_top_id right_top_id terminal_pane_id logs_pane_id

  load_layout_vars "$layout_name"

  # Nome window = nome cartella progetto (non "main")
  local project_name
  project_name="$(tmux display-message -p -t "$session_name":0 '#{b:session_path}')" || project_name="main"
  tmux rename-window -t "$session_name":0 "$project_name"

  full_pane="$(tmux display-message -p -t "$session_name":0.0 '#{pane_id}')"

  # 1. Taglia il git bar in fondo (2 righe, larghezza piena)
  local git_lines="${gitbar_lines:-2}"
  gitbar_pane="$(tmux split-window -v -l "$git_lines" -t "$full_pane" -P -F '#{pane_id}')"

  # 2. Nella zona superiore: split orizzontale → filetree (sx) | claude+terminal (dx)
  right_top_id="$(tmux split-window -h -p "$claude_width" -t "$full_pane" -P -F '#{pane_id}')"
  left_top_id="$full_pane"

  # 3. Split verticale colonna destra: claude (alto) | area-bassa (basso)
  terminal_pane_id="$(tmux split-window -v -p "$lower_height" -t "$right_top_id" -P -F '#{pane_id}')"

  # 4. Split verticale area-bassa: terminal (sopra) | logs (sotto)
  logs_pane_id="$(tmux split-window -v -p 50 -t "$terminal_pane_id" -P -F '#{pane_id}')"

  sleep 1

  # Marca i pane con il loro ruolo a livello pane (-p), non window
  tmux set-option -p -t "$left_top_id"      @bigide_pane_type "yazi"
  tmux set-option -p -t "$right_top_id"     @bigide_pane_type "claude"
  tmux set-option -p -t "$terminal_pane_id" @bigide_pane_type "terminal"
  tmux set-option -p -t "$logs_pane_id"     @bigide_pane_type "logs"
  tmux set-option -p -t "$gitbar_pane"      @bigide_pane_type "gitbar"

  # Project path dalla sessione tmux (impostato da bigide con -c "$PROJECT_PATH")
  # Espande ~ → $HOME (tmux può restituire path con tilde letterale)
  local project_path
  project_path="$(tmux display-message -p -t "${session_name}" '#{session_path}')"
  project_path="${project_path/#\~/$HOME}"

  # Salva project path per _restart_claude_resume e altri script
  echo "$project_path" > "$BIGIDE_HOME/active-project-path"

  # ── Per-window state: runner + project path ──────────────────────────────────
  local win_id
  win_id="$(tmux display-message -p -t "$session_name":0 '#{window_id}')"
  tmux set-option -w -t "$win_id" @bigide_project_path "$project_path"
  local default_runner
  default_runner="$(cat "$BIGIDE_HOME/active-runner" 2>/dev/null)" || default_runner="anthropic"
  [[ -z "$default_runner" ]] && default_runner="anthropic"
  tmux set-option -w -t "$win_id" @bigide_runner "$default_runner"
  local display_name
  case "$default_runner" in
    anthropic) display_name="claude" ;;
    openai)    display_name="codex" ;;
    gemini)    display_name="gemini" ;;
    *)         display_name="$default_runner" ;;
  esac
  tmux set-option -w -t "$win_id" @bigide_runner_display "$display_name"

  bide_log "PANE" "create_layout session=$session_name layout=$layout_name path=$project_path"
  bide_log "PANE" "panes: yazi=$left_top_id claude=$right_top_id terminal=$terminal_pane_id logs=$logs_pane_id gitbar=$gitbar_pane"

  # Avvio strumenti — cd esplicito in ogni pane per sicurezza
  bide_log "PANE" "send $left_top_id [yazi] ← filetree.sh"
  tmux send-keys -t "$left_top_id"      "cd '${project_path}' && clear; \$HOME/.bigide/scripts/filetree.sh" C-m
  # Resize-trick: forza nvim a ridisegnare dopo startup (1col ±1 → evento resize → redraw completo)
  { sleep 5 && tmux resize-pane -t "${left_top_id}" -x 41 2>/dev/null && sleep 0.2 && tmux resize-pane -t "${left_top_id}" -x 40 2>/dev/null; } &
  bide_log "PANE" "send $right_top_id [claude] ← launch-claude.sh"
  tmux send-keys -t "$right_top_id"     "cd '${project_path}' && clear; \$HOME/.bigide/scripts/launch-claude.sh" C-m
  bide_log "PANE" "send $terminal_pane_id [terminal] ← shell"
  tmux send-keys -t "$terminal_pane_id" "cd '${project_path}' && clear && exec zsh" C-m
  bide_log "PANE" "send $logs_pane_id [logs] ← log-viewer.sh"
  tmux send-keys -t "$logs_pane_id"     'clear; $HOME/.bigide/scripts/log-viewer.sh' C-m
  bide_log "PANE" "send $gitbar_pane [gitbar] ← git-bar.sh loop"
  tmux send-keys -t "$gitbar_pane" "while true; do bash \$HOME/.bigide/scripts/git-bar.sh '${project_path}' 2>/dev/null; sleep 2; done" C-m

  # Hook: resize dinamico — adatta layout in base alla larghezza finestra
  local win_id_for_hook
  win_id_for_hook="$(tmux display-message -p -t "$session_name":0 '#{window_id}')"
  tmux set-hook -t "$session_name" client-resized \
    "run-shell 'bash \$HOME/.bigide/scripts/resize-layout.sh \"${win_id_for_hook}\"'"
  bide_log "HOOK" "registered client-resized → resize-layout.sh [session=$session_name win=$win_id_for_hook]"

  # Seleziona claude come pane attivo
  tmux select-pane -t "$right_top_id"
}

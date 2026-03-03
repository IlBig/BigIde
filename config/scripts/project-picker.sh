#!/usr/bin/env bash
# BigIDE — Project Picker con fzf
# Naviga cartelle e apri progetti in nuovi tab tmux
# Chiamato da tmux popup (prefix + a)
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

BIGIDE_HOME="${BIGIDE_HOME:-$HOME/.bigide}"
_L() { printf '%s [EVENT] project-picker: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$BIGIDE_HOME/logs/bigide.log" 2>/dev/null || true; }

# ─── Auto-reload: se il repo ha una versione più recente, esegui quella ─────
_REPO_ROOT="$(cat "$BIGIDE_HOME/.repo_root" 2>/dev/null)" || true
if [[ -n "$_REPO_ROOT" ]]; then
  _REPO_SCRIPT="$_REPO_ROOT/config/scripts/project-picker.sh"
  _SELF="${BASH_SOURCE[0]}"
  if [[ -f "$_REPO_SCRIPT" && "$_SELF" != "$_REPO_SCRIPT" && "$_REPO_SCRIPT" -nt "$_SELF" ]]; then
    exec bash "$_REPO_SCRIPT" "$@"
  fi
  BIGIDE_REPO_ROOT="$_REPO_ROOT"
else
  BIGIDE_REPO_ROOT="__BIGIDE_REPO_ROOT__"
fi

# ─── Sessione e directory corrente ──────────────────────────────────────────
CURRENT_SESSION="$(tmux display-message -p '#S')"
SESSION_PATH="$(tmux display-message -p '#{session_path}' 2>/dev/null)" || SESSION_PATH="$HOME"
SESSION_PATH="${SESSION_PATH/#\~/$HOME}"
# Se session_path è $HOME, prova active-project-path
if [[ "$SESSION_PATH" == "$HOME" ]]; then
  _alt="$(cat "$HOME/.bigide/active-project-path" 2>/dev/null)" || true
  [[ -n "$_alt" && -d "$_alt" ]] && SESSION_PATH="$_alt"
fi
CURRENT_DIR="$(dirname "$SESSION_PATH")"
[[ -d "$CURRENT_DIR" ]] || CURRENT_DIR="$HOME"

# ─── Colori Tokyo Night (RGB) ──────────────────────────────────────────────
GREEN=$'\033[38;2;158;206;106m'   # #9ece6a
BLUE=$'\033[38;2;122;162;247m'    # #7aa2f7
DIM=$'\033[38;2;86;95;137m'       # #565f89
WHITE=$'\033[38;2;192;202;245m'   # #c0caf5
RESET=$'\033[0m'

FZF_COLORS='bg:#1a1b26,bg+:#2e3c64,fg:#a9b1d6,fg+:#c0caf5,hl:#ff9e64,hl+:#ff9e64,border:#3b4261,header:#565f89,prompt:#7aa2f7,pointer:#7aa2f7,marker:#9ece6a,info:#565f89'

# ─── Helper: nome sessione BigIDE per un path ──────────────────────────────
_session_name() {
  local base
  base="$(basename "$1")"
  echo "bigide-${base//[^[:alnum:]]/-}"
}

# ─── Helper: controlla se sessione tmux esiste ─────────────────────────────
_session_exists() {
  tmux has-session -t "$1" 2>/dev/null
}

# ─── Helper: controlla se window con nome esiste nella sessione corrente ───
_window_exists() {
  tmux list-windows -t "$CURRENT_SESSION" -F '#W' 2>/dev/null | grep -qxF "$1"
}

# ─── Crea nuovo tab con layout BigIDE completo ─────────────────────────────
_open_project_tab() {
  local project_path="$1"
  local project_name
  project_name="$(basename "$project_path")"

  # Se tab con questo nome esiste già, switch ad esso
  if _window_exists "$project_name"; then
    tmux select-window -t "${CURRENT_SESSION}:=${project_name}"
    return 0
  fi

  # Carica percentuali dal layout default
  local layout_file="$BIGIDE_HOME/layouts/default.json"
  local claude_pct=80 lower_pct=35 git_lines=1
  if [[ -f "$layout_file" ]] && command -v jq &>/dev/null; then
    claude_pct="$(jq -r '.panes[] | select(.id=="claude") | .widthPercent' "$layout_file" 2>/dev/null)" || claude_pct=80
    lower_pct="$(jq -r '.panes[] | select(.id=="terminal") | .heightPercent' "$layout_file" 2>/dev/null)" || lower_pct=35
    git_lines="$(jq -r '.panes[] | select(.id=="gitbar") | .heightLines // 1' "$layout_file" 2>/dev/null)" || git_lines=1
  fi

  # Nuovo window
  tmux new-window -t "$CURRENT_SESSION" -n "$project_name" -c "$project_path"

  local full_pane
  full_pane="$(tmux display-message -p -t "${CURRENT_SESSION}:=${project_name}" '#{pane_id}')"

  # 1. Git bar in fondo
  local gitbar_pane
  gitbar_pane="$(tmux split-window -v -l "$git_lines" -t "$full_pane" -c "$project_path" -P -F '#{pane_id}')"

  # 2. Split orizzontale: filetree (sx) | area destra (dx)
  local right_top_id
  right_top_id="$(tmux split-window -h -p "$claude_pct" -t "$full_pane" -c "$project_path" -P -F '#{pane_id}')"
  local left_top_id="$full_pane"

  # 3. Split verticale colonna destra: claude (alto) | area-bassa (basso)
  local terminal_pane_id
  terminal_pane_id="$(tmux split-window -v -p "$lower_pct" -t "$right_top_id" -c "$project_path" -P -F '#{pane_id}')"

  # 4. Split orizzontale area-bassa: terminal (sx) | logs (dx)
  local logs_pane_id
  logs_pane_id="$(tmux split-window -h -p 50 -t "$terminal_pane_id" -c "$project_path" -P -F '#{pane_id}')"

  sleep 1

  # Marca pane con ruolo
  tmux set-option -p -t "$left_top_id"      @bigide_pane_type "yazi"
  tmux set-option -p -t "$right_top_id"     @bigide_pane_type "claude"
  tmux set-option -p -t "$terminal_pane_id" @bigide_pane_type "terminal"
  tmux set-option -p -t "$logs_pane_id"     @bigide_pane_type "logs"
  tmux set-option -p -t "$gitbar_pane"      @bigide_pane_type "gitbar"

  # ── Per-window state: runner + project path ──────────────────────────────────
  local win_id
  win_id="$(tmux display-message -p -t "${CURRENT_SESSION}:=${project_name}" '#{window_id}')"
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

  # Avvio strumenti — tutti puntano al progetto selezionato
  tmux send-keys -t "$left_top_id"      "cd '${project_path}' && clear && \$HOME/.bigide/scripts/filetree.sh" C-m
  { sleep 5 && tmux resize-pane -t "$left_top_id" -x 41 2>/dev/null && sleep 0.2 && tmux resize-pane -t "$left_top_id" -x 40 2>/dev/null; } &
  tmux send-keys -t "$right_top_id"     "cd '${project_path}' && clear && \$HOME/.bigide/scripts/launch-claude.sh" C-m
  tmux send-keys -t "$terminal_pane_id" "cd '${project_path}' && clear && zsh" C-m
  tmux send-keys -t "$logs_pane_id"     "cd '${project_path}' && clear && zsh" C-m
  tmux send-keys -t "$gitbar_pane"      "while true; do bash \$HOME/.bigide/scripts/git-bar.sh '${project_path}' 2>/dev/null; sleep 2; done" C-m

  # Resize hook per il nuovo window
  tmux set-hook -t "$CURRENT_SESSION" client-resized \
    "run-shell 'tw=\$(tmux display-message -p \"#{window_width}\"); half=\$(( (tw - 42) / 2 )); tmux resize-pane -t ${left_top_id} -x 40 2>/dev/null; tmux resize-pane -t ${gitbar_pane} -y 1 2>/dev/null; tmux resize-pane -t ${terminal_pane_id} -x \$half 2>/dev/null; true'"

  # Resize esplicito — allinea alle stesse dimensioni del layout principale
  local tw
  tw="$(tmux display-message -p -t "${CURRENT_SESSION}:=${project_name}" '#{window_width}' 2>/dev/null)" || tw=160
  local half=$(( (tw - 42) / 2 ))
  tmux resize-pane -t "$left_top_id" -x 40 2>/dev/null || true
  tmux resize-pane -t "$gitbar_pane" -y 1 2>/dev/null || true
  tmux resize-pane -t "$terminal_pane_id" -x "$half" 2>/dev/null || true

  # Seleziona claude come pane attivo
  tmux select-pane -t "$right_top_id"
}

# ─── Loop principale di navigazione ────────────────────────────────────────
navigate() {
  local dir="$1"

  while true; do
    # Costruisci lista con colori ANSI
    local entries=()
    entries+=("${BLUE}+${RESET}  Nuova cartella")
    [[ "$dir" != "/" ]] && entries+=("${DIM}..${RESET} Cartella superiore")

    while IFS= read -r folder; do
      [[ -z "$folder" ]] && continue
      local name
      name="$(basename "$folder")"
      [[ "$name" == .* ]] && continue

      local session_name
      session_name="$(_session_name "$folder")"
      if _session_exists "$session_name" || _window_exists "$name"; then
        entries+=("${GREEN}●${RESET}  ${WHITE}${name}${RESET}")
      else
        entries+=("   ${name}")
      fi
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

    local short_dir="${dir/#$HOME/\~}"

    local selected
    selected=$(printf '%s\n' "${entries[@]}" | fzf \
      --height=100% \
      --layout=reverse \
      --border=rounded \
      --prompt=" Progetti  " \
      --pointer="▶" \
      --marker="●" \
      --header=" ${short_dir}   Enter entra  │  Ctrl-O apri progetto  │  Esc chiudi" \
      --expect=ctrl-o \
      --color="$FZF_COLORS" \
      --no-multi \
      --ansi \
    ) || return 0

    # Parsing output fzf con --expect: riga 1 = tasto, riga 2+ = selezione
    local key line
    IFS= read -r key <<< "$selected"
    line="$(tail -n +2 <<< "$selected")"

    _L "fzf: key=[$key] line=[$line]"
    [[ -z "$line" ]] && continue

    # Rimuovi codici ANSI per il matching
    local clean
    clean="$(sed $'s/\033\\[[0-9;]*m//g' <<< "$line")"

    # ─── Estrai nome cartella (rimuovi indicatore ● e spazi) ────────
    local folder_name
    folder_name="$(echo "$clean" | sed 's/^[●+ ]*//' | xargs)"

    # ─── Ctrl-O → apri progetto (check PRIMA del contenuto) ────────
    if [[ "$key" == "ctrl-o" ]]; then
      local target="$dir/$folder_name"
      # Se il target selezionato non è una cartella valida, apri $dir (la cartella corrente)
      if [[ ! -d "$target" ]]; then
        target="$dir"
      fi
      _L "ctrl-o: opening [$target] (session=$CURRENT_SESSION)"
      _open_project_tab "$target" 2>>"$BIGIDE_HOME/logs/bigide.log" || _L "ERROR: _open_project_tab failed: $?"
      return 0
    fi

    # ─── Enter: gestisci in base al contenuto ───────────────────────
    if [[ "$clean" == *"Nuova cartella"* ]]; then
      local new_name=""
      printf "${BLUE}"
      read -r -p "  Nome: " new_name
      printf "${RESET}"
      if [[ -n "$new_name" ]]; then
        mkdir -p "$dir/$new_name"
      fi
      continue
    fi

    if [[ "$clean" == *"Cartella superiore"* ]]; then
      dir="$(dirname "$dir")"
      continue
    fi

    local target="$dir/$folder_name"
    if [[ -d "$target" ]]; then
      dir="$target"
    fi
  done
}

navigate "$CURRENT_DIR"

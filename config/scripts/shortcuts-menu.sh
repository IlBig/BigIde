#!/usr/bin/env bash
# BigIDE — Shortcuts Menu (fzf launcher)
# Scansiona ~/.bigide/shortcuts/*.sh e li esegue in popup tmux
# Chiamato da tmux popup (prefix + x)
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

BIGIDE_HOME="${BIGIDE_HOME:-$HOME/.bigide}"
SHORTCUTS_DIR="$BIGIDE_HOME/shortcuts"
_L() { printf '%s [EVENT] shortcuts-menu: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$BIGIDE_HOME/logs/bigide.log" 2>/dev/null || true; }

# ─── Auto-reload: se il repo ha una versione più recente, esegui quella ─────
_REPO_ROOT="$(cat "$BIGIDE_HOME/.repo_root" 2>/dev/null)" || true
if [[ -n "$_REPO_ROOT" ]]; then
  _REPO_SCRIPT="$_REPO_ROOT/config/scripts/shortcuts-menu.sh"
  _SELF="${BASH_SOURCE[0]}"
  if [[ -f "$_REPO_SCRIPT" && "$_SELF" != "$_REPO_SCRIPT" && "$_REPO_SCRIPT" -nt "$_SELF" ]]; then
    exec bash "$_REPO_SCRIPT" "$@"
  fi
fi

# ─── Colori Tokyo Night (fzf) ────────────────────────────────────────────────
FZF_COLORS='bg:#1a1b26,bg+:#2e3c64,fg:#a9b1d6,fg+:#c0caf5,hl:#ff9e64,hl+:#ff9e64,border:#3b4261,header:#565f89,prompt:#7aa2f7,pointer:#7aa2f7,marker:#9ece6a,info:#565f89'

# ─── Project path dalla sessione tmux ────────────────────────────────────────
PROJECT_PATH="$(tmux display-message -p '#{session_path}' 2>/dev/null)" || PROJECT_PATH="$PWD"
PROJECT_PATH="${PROJECT_PATH/#\~/$HOME}"
# Prova window-level override
if [[ -n "${BIGIDE_WINDOW:-}" ]]; then
  _wp="$(tmux show-option -wv -t "$BIGIDE_WINDOW" @bigide_project_path 2>/dev/null)" || true
  [[ -n "$_wp" ]] && PROJECT_PATH="$_wp"
fi

# ─── Scansiona shortcuts ─────────────────────────────────────────────────────
if [[ ! -d "$SHORTCUTS_DIR" ]] || ! ls "$SHORTCUTS_DIR"/*.sh &>/dev/null; then
  echo "Nessuno shortcut trovato in $SHORTCUTS_DIR"
  echo "Premi un tasto per chiudere..."
  read -rsn1
  exit 0
fi

declare -a LABELS=()
declare -a SCRIPTS=()

for script in "$SHORTCUTS_DIR"/*.sh; do
  [[ -f "$script" ]] || continue

  # Leggi metadati dall'header
  name="$(grep -m1 '^# @name:' "$script" | sed 's/^# @name:[[:space:]]*//')" || true
  desc="$(grep -m1 '^# @desc:' "$script" | sed 's/^# @desc:[[:space:]]*//')" || true
  icon="$(grep -m1 '^# @icon:' "$script" | sed 's/^# @icon:[[:space:]]*//')" || true

  # Fallback: usa nome file senza estensione
  [[ -z "$name" ]] && name="$(basename "$script" .sh)"

  # Costruisci label per fzf
  local_icon="${icon:-▸}"
  if [[ -n "$desc" ]]; then
    label="$local_icon  $name — $desc"
  else
    label="$local_icon  $name"
  fi

  LABELS+=("$label")
  SCRIPTS+=("$script")
done

if [[ ${#LABELS[@]} -eq 0 ]]; then
  echo "Nessuno shortcut trovato."
  echo "Premi un tasto per chiudere..."
  read -rsn1
  exit 0
fi

# ─── Mostra menu fzf ────────────────────────────────────────────────────────
selected=$(printf '%s\n' "${LABELS[@]}" | fzf \
  --height=100% \
  --layout=reverse \
  --border=rounded \
  --prompt="  Shortcuts  " \
  --pointer="▶" \
  --header="  Enter esegui  │  Esc chiudi" \
  --color="$FZF_COLORS" \
  --no-multi \
  --ansi \
) || exit 0

# ─── Trova script corrispondente ─────────────────────────────────────────────
selected_script=""
for i in "${!LABELS[@]}"; do
  if [[ "${LABELS[$i]}" == "$selected" ]]; then
    selected_script="${SCRIPTS[$i]}"
    break
  fi
done

if [[ -z "$selected_script" ]]; then
  _L "WARN: nessuno script trovato per selezione: $selected"
  exit 1
fi

_L "Esecuzione shortcut: $selected_script (project=$PROJECT_PATH)"

# ─── Esegui nel pane terminal ─────────────────────────────────────────────────
# Trova il pane terminal del window corrente
TERM_PANE=""
if [[ -n "${BIGIDE_WINDOW:-}" ]]; then
  TERM_PANE="$(tmux list-panes -t "$BIGIDE_WINDOW" -F '#{pane_id} #{@bigide_pane_type}' 2>/dev/null \
    | awk '$2 == "terminal" {print $1; exit}')" || true
fi
# Fallback: cerca in tutti i pane
if [[ -z "$TERM_PANE" ]]; then
  TERM_PANE="$(tmux list-panes -F '#{pane_id} #{@bigide_pane_type}' 2>/dev/null \
    | awk '$2 == "terminal" {print $1; exit}')" || true
fi

if [[ -n "$TERM_PANE" ]]; then
  tmux send-keys -t "$TERM_PANE" "bash '${selected_script}'" C-m
else
  _L "WARN: nessun pane terminal trovato, fallback popup"
  tmux display-popup -E \
    -s "bg=#1a1b26" -S "fg=#3b4261,bg=#1a1b26" \
    -w "80%" -h "80%" -x "C" -y "C" \
    "BIGIDE_PROJECT_PATH='${PROJECT_PATH}' bash '${selected_script}'"
fi

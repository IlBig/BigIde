#!/usr/bin/env bash
# BigIDE — Shortcuts Menu (fzf launcher)
# Scansiona ~/.bigide/shortcuts/*.sh e li esegue in popup tmux
# Chiamato da tmux popup (Ctrl+s)
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

# ─── Colori Tokyo Night ──────────────────────────────────────────────────────
FZF_COLORS='bg:#1a1b26,bg+:#2e3c64,fg:#a9b1d6,fg+:#c0caf5,hl:#ff9e64,hl+:#ff9e64,border:#3b4261,header:#565f89,prompt:#7aa2f7,pointer:#7aa2f7,marker:#9ece6a,info:#565f89'
_CYAN=$'\033[38;2;125;207;255m'
_DIM=$'\033[38;2;86;95;137m'
_VIOLET=$'\033[38;2;187;154;247m'
_RST=$'\033[0m'

# Temp file per comunicare l'azione da fzf --bind
ACTION_FILE="$(mktemp)"
trap 'rm -f "$ACTION_FILE"' EXIT

# ─── Scansiona e mostra menu (loop per rename/edit) ──────────────────────────
while true; do

  if [[ ! -d "$SHORTCUTS_DIR" ]] || ! ls "$SHORTCUTS_DIR"/*.sh &>/dev/null; then
    echo "Nessuno shortcut trovato in $SHORTCUTS_DIR"
    echo "Premi un tasto per chiudere..."
    read -rsn1
    exit 0
  fi

  # Calcola larghezza max dei nomi file per allineamento colonne
  max_name=0
  for script in "$SHORTCUTS_DIR"/*.sh; do
    [[ -f "$script" ]] || continue
    fname="$(basename "$script")"
    (( ${#fname} > max_name )) && max_name=${#fname}
  done

  declare -a LABELS=()
  declare -a SCRIPTS=()

  for script in "$SHORTCUTS_DIR"/*.sh; do
    [[ -f "$script" ]] || continue
    fname="$(basename "$script")"
    desc="$(grep -m1 '^# @desc:' "$script" | sed 's/^# @desc:[[:space:]]*//')" || true

    label="$(printf "%-${max_name}s  ${_DIM}│${_RST}  %s" "$fname" "$desc")"
    LABELS+=("$label")
    SCRIPTS+=("$script")
  done

  if [[ ${#LABELS[@]} -eq 0 ]]; then
    echo "Nessuno shortcut trovato."
    echo "Premi un tasto per chiudere..."
    read -rsn1
    exit 0
  fi

  # Reset action file
  : > "$ACTION_FILE"

  # ─── Menu fzf ──────────────────────────────────────────────────────────────
  # --bind scrive l'azione nel temp file, poi accetta → fzf esce con la selezione
  selected=$(printf '%s\n' "${LABELS[@]}" | fzf \
    --height=100% \
    --layout=reverse \
    --border=rounded \
    --prompt="  Shortcuts  " \
    --pointer="▶" \
    --header="  Enter esegui  │  F2 rinomina  │  F3 modifica  │  F4 elimina  │  Esc chiudi" \
    --bind "f2:execute-silent(echo rename > $ACTION_FILE)+accept" \
    --bind "f3:execute-silent(echo edit > $ACTION_FILE)+accept" \
    --bind "f4:execute-silent(echo delete > $ACTION_FILE)+accept" \
    --color="$FZF_COLORS" \
    --no-multi \
    --ansi \
  ) || exit 0

  [[ -z "$selected" ]] && continue

  action="$(cat "$ACTION_FILE" 2>/dev/null)" || true

  # ─── Trova script corrispondente (dal nome file nella prima colonna) ───────
  selected_fname="$(awk '{print $1}' <<< "$selected")"
  selected_script="$SHORTCUTS_DIR/$selected_fname"
  [[ ! -f "$selected_script" ]] && continue

  # ─── F2: Rinomina (file + descrizione) ──────────────────────────────────────
  if [[ "$action" == "rename" ]]; then
    old_fname="$(basename "$selected_script")"
    old_desc="$(grep -m1 '^# @desc:' "$selected_script" | sed 's/^# @desc:[[:space:]]*//')" || true

    printf '\033[2J\033[H'
    printf '\n  %sRinomina shortcut%s\n' "$_VIOLET" "$_RST"
    printf '  %s──────────────────────────────────────%s\n' "$_DIM" "$_RST"
    printf '\n  %sCtrl+C = annulla%s\n\n' "$_DIM" "$_RST"

    # Nome file — precompilato editabile
    new_fname=""
    read -rep "  File: " -i "$old_fname" new_fname || { unset LABELS SCRIPTS; continue; }
    [[ -z "$new_fname" ]] && { unset LABELS SCRIPTS; continue; }
    # Assicura estensione .sh
    [[ "$new_fname" != *.sh ]] && new_fname="${new_fname}.sh"

    # Descrizione — precompilata editabile
    new_desc=""
    read -rep "  Desc: " -i "$old_desc" new_desc || { unset LABELS SCRIPTS; continue; }

    # Rinomina file se cambiato (runtime + sorgente repo)
    if [[ "$new_fname" != "$old_fname" ]]; then
      mv "$selected_script" "$SHORTCUTS_DIR/$new_fname"
      selected_script="$SHORTCUTS_DIR/$new_fname"
      # Rinomina anche nel repo sorgente per evitare che setup-runtime ricrei il vecchio
      if [[ -n "${_REPO_ROOT:-}" && -f "$_REPO_ROOT/config/shortcuts/$old_fname" ]]; then
        mv "$_REPO_ROOT/config/shortcuts/$old_fname" "$_REPO_ROOT/config/shortcuts/$new_fname"
      fi
      _L "File: $old_fname → $new_fname"
    fi

    # Aggiorna descrizione se cambiata (runtime + sorgente repo)
    if [[ "$new_desc" != "$old_desc" ]]; then
      for _target in "$selected_script" "$_REPO_ROOT/config/shortcuts/$new_fname"; do
        [[ -f "$_target" ]] || continue
        if grep -q '^# @desc:' "$_target"; then
          sed -i '' "s/^# @desc:.*$/# @desc: ${new_desc}/" "$_target"
        else
          sed -i '' "1a\\
# @desc: ${new_desc}" "$_target"
        fi
      done
      _L "Desc: $old_desc → $new_desc ($selected_script)"
    fi

    unset LABELS SCRIPTS
    continue
  fi

  # ─── F3: Modifica script in nvim ──────────────────────────────────────────
  if [[ "$action" == "edit" ]]; then
    _L "Edit shortcut: $selected_script"
    NVIM_APPNAME=bigide nvim "$selected_script" </dev/tty
    unset LABELS SCRIPTS
    continue
  fi

  # ─── F4: Elimina shortcut ──────────────────────────────────────────────────
  if [[ "$action" == "delete" ]]; then
    del_fname="$(basename "$selected_script")"
    printf '\033[2J\033[H'
    printf '\n  %sElimina shortcut%s\n' "$_VIOLET" "$_RST"
    printf '  %s──────────────────────────────────────%s\n' "$_DIM" "$_RST"
    printf '\n  File: %s%s%s\n\n' "$_CYAN" "$del_fname" "$_RST"
    printf '  Confermi eliminazione? [s/N] '
    read -rsn1 confirm </dev/tty
    echo ""
    if [[ "$confirm" == "s" || "$confirm" == "S" ]]; then
      rm -f "$selected_script"
      # Rimuovi anche dal repo sorgente
      if [[ -n "${_REPO_ROOT:-}" && -f "$_REPO_ROOT/config/shortcuts/$del_fname" ]]; then
        rm -f "$_REPO_ROOT/config/shortcuts/$del_fname"
      fi
      _L "Eliminato: $del_fname"
    fi
    unset LABELS SCRIPTS
    continue
  fi

  # ─── Enter: Esegui ────────────────────────────────────────────────────────
  _L "Esecuzione shortcut: $selected_script"

  TERM_PANE=""
  if [[ -n "${BIGIDE_WINDOW:-}" ]]; then
    TERM_PANE="$(tmux list-panes -t "$BIGIDE_WINDOW" -F '#{pane_id} #{@bigide_pane_type}' 2>/dev/null \
      | awk '$2 == "terminal" {print $1; exit}')" || true
  fi
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
      "bash '${selected_script}'"
  fi
  exit 0

done

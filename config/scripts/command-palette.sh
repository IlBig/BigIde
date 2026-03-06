#!/usr/bin/env bash
# BigIDE — Command Palette (stile VSCode)
# C-a: apre subito, tasto diretto esegue, Esc chiude BigIDE
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

BIGIDE_HOME="${BIGIDE_HOME:-$HOME/.bigide}"
_S="$HOME/.bigide/scripts"

# ─── Risolvi BIGIDE_WINDOW se tmux non ha espanso il format string ────────────
if [[ -z "${BIGIDE_WINDOW:-}" || "${BIGIDE_WINDOW:-}" == *'#{'* ]]; then
  BIGIDE_WINDOW="$(tmux display-message -p '#{window_id}' 2>/dev/null)" || true
fi
export BIGIDE_WINDOW

_L() { printf '%s [EVENT] palette: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$BIGIDE_HOME/logs/bigide.log" 2>/dev/null || true; }

# Sessione BigIDE — passata via env dal binding tmux, fallback display-message
_SESSION="${BIGIDE_SESSION:-$(tmux display-message -p '#{session_name}' 2>/dev/null || echo '')}"

# ─── Auto-reload ─────────────────────────────────────────────────────────────
_REPO_ROOT="$(cat "$BIGIDE_HOME/.repo_root" 2>/dev/null)" || true
if [[ -n "$_REPO_ROOT" ]]; then
  _REPO_SCRIPT="$_REPO_ROOT/config/scripts/command-palette.sh"
  _SELF="${BASH_SOURCE[0]}"
  if [[ -f "$_REPO_SCRIPT" && "$_SELF" != "$_REPO_SCRIPT" && "$_REPO_SCRIPT" -nt "$_SELF" ]]; then
    exec bash "$_REPO_SCRIPT" "$@"
  fi
fi

# ─── Colori Tokyo Night ──────────────────────────────────────────────────────
_C_DIM=$'\033[38;2;86;95;137m'
_C_CYAN=$'\033[38;2;125;207;255m'
_C_WHITE=$'\033[38;2;192;202;245m'
_C_VIOLET=$'\033[38;2;187;154;247m'
_C_ORANGE=$'\033[38;2;255;158;100m'
_C_FRAME=$'\033[38;2;59;66;97m'
_C_RESET=$'\033[0m'

# ─── Comandi ─────────────────────────────────────────────────────────────────
# Format: "shortcut|label|type|target"
#   exec → exec script nel popup corrente (sostituisce palette)
#   run  → tmux run-shell in background, poi chiude palette
#   tmux → comando tmux inline, poi chiude palette
_ITEMS=(
  "f|File Search|exec|$_S/file-search.sh"
  "v|Voice Dictation|exec|$_S/voice-dictation.sh"
  "p|Perplexity|run|$_S/perplexity-toggle.sh"
  "a|Apri progetto|exec|$_S/project-picker.sh"
  "s|Safari 50/50|run|$_S/open-browser.sh"
  "c|Chrome DevTools|run|$_S/open-devtools.sh"
  "e|File Tree|tmux|filetree"
  "m|AI Provider|exec|$_S/runner-selector.sh"
  "g|Lazygit|exec|$_S/git-lazygit.sh"
  "b|Git Branch|exec|$_S/git-branch.sh"
  "z|Zoom Pannello|tmux|zoom"
  "?|Help|exec|$_S/which-key.sh"
)
_N=${#_ITEMS[@]}

# ─── Helpers ─────────────────────────────────────────────────────────────────
_goto() { printf '\033[%d;%dH' "$1" "$2"; }
_detect_size() {
  local size
  if [[ -t 0 ]] && size=$(stty size 2>/dev/null) && [[ -n "$size" ]]; then
    TERM_H="${size%% *}"; TERM_W="${size##* }"
  else
    TERM_W="${COLUMNS:-80}"; TERM_H="${LINES:-24}"
  fi
}

# ─── Esegui azione ───────────────────────────────────────────────────────────
_execute() {
  local idx="$1"
  local entry="${_ITEMS[$idx]}"
  local shortcut="${entry%%|*}";  local rest="${entry#*|}"
  local label="${rest%%|*}";      rest="${rest#*|}"
  local type="${rest%%|*}";       local target="${rest#*|}"

  _L "[$shortcut] $label"
  tput cnorm 2>/dev/null || true

  case "$type" in
    exec)
      # Sostituisce la palette con lo script — il popup rimane aperto
      exec bash "$target"
      ;;
    run)
      # Esegue in background tmux, chiude palette
      tmux run-shell "bash '$target'"
      exit 0
      ;;
    tmux)
      case "$target" in
        filetree)
          local _yp=""
          if [[ -n "${BIGIDE_WINDOW:-}" ]]; then
            _yp=$(tmux list-panes -t "$BIGIDE_WINDOW" -F '#{pane_id} #{@bigide_pane_type}' 2>/dev/null \
              | awk '$2=="yazi"{print $1;exit}')
          fi
          [[ -z "$_yp" ]] && _yp=":.0"
          tmux run-shell "pw=\$(tmux display-message -p -t '$_yp' '#{pane_width}'); if [ \"\$pw\" -le 3 ]; then tmux resize-pane -t '$_yp' -x 40; else tmux resize-pane -t '$_yp' -x 1; fi"
          ;;
        zoom)
          tmux resize-pane -Z
          ;;
      esac
      exit 0
      ;;
  esac
}

# ─── Disegna palette ─────────────────────────────────────────────────────────
_draw() {
  local sel="$1"
  _detect_size

  local box_w=46
  local box_h=$(( _N + 7 ))
  local col=$(( (TERM_W - box_w - 2) / 2 ))
  local top=$(( (TERM_H - box_h) / 2 ))
  (( col < 1 )) && col=1 || true
  (( top < 1 )) && top=1 || true

  local r=$top c=$col w=$box_w opad=4

  # Top border
  _goto "$r" "$c"
  printf '%s┌' "$_C_FRAME"; printf '─%.0s' $(seq 1 "$w"); printf '┐%s' "$_C_RESET"
  (( r++ ))

  # Empty
  _goto "$r" "$c"; printf '%s│%*s│%s' "$_C_FRAME" "$w" "" "$_C_RESET"; (( r++ ))

  # Title
  local title="Comandi BigIDE"
  local tpad=$(( (w - ${#title}) / 2 ))
  _goto "$r" "$c"
  printf '%s│%*s%s%s%*s%s│%s' \
    "$_C_FRAME" "$tpad" "" "$_C_VIOLET" "$title" $(( w - tpad - ${#title} )) "" "$_C_FRAME" "$_C_RESET"
  (( r++ ))

  # Empty
  _goto "$r" "$c"; printf '%s│%*s│%s' "$_C_FRAME" "$w" "" "$_C_RESET"; (( r++ ))

  # Items
  for i in "${!_ITEMS[@]}"; do
    local entry="${_ITEMS[$i]}"
    local sk="${entry%%|*}"
    local lbl="${entry#*|}"; lbl="${lbl%%|*}"

    local mark badge_col text_col
    if (( i == sel )); then
      mark="▸ "; badge_col="$_C_ORANGE"; text_col="$_C_CYAN"
    else
      mark="  "; badge_col="$_C_DIM";    text_col="$_C_WHITE"
    fi

    local badge="[$sk]"
    # lunghezza visibile: mark(2) + badge(3) + "  "(2) + lbl
    local line_len=$(( 2 + ${#badge} + 2 + ${#lbl} ))
    local pad=$(( w - opad - line_len ))
    (( pad < 0 )) && pad=0

    _goto "$r" "$c"
    printf '%s│%*s%s%s%s%s  %s%s%*s%s│%s' \
      "$_C_FRAME" "$opad" "" \
      "$text_col" "$mark" "$badge_col" "$badge" \
      "$text_col" "$lbl" "$pad" "" \
      "$_C_FRAME" "$_C_RESET"
    (( r++ ))
  done

  # Empty
  _goto "$r" "$c"; printf '%s│%*s│%s' "$_C_FRAME" "$w" "" "$_C_RESET"; (( r++ ))

  # Footer
  local hint="↑↓ naviga  tasto esegue  Esc chiudi  q esci"
  local hpad=$(( (w - ${#hint}) / 2 ))
  _goto "$r" "$c"
  printf '%s│%*s%s%s%*s%s│%s' \
    "$_C_FRAME" "$hpad" "" "$_C_DIM" "$hint" $(( w - hpad - ${#hint} )) "" "$_C_FRAME" "$_C_RESET"
  (( r++ ))

  # Bottom border
  _goto "$r" "$c"
  printf '%s└' "$_C_FRAME"; printf '─%.0s' $(seq 1 "$w"); printf '┘%s' "$_C_RESET"
}

# ─── Main ────────────────────────────────────────────────────────────────────
_main() {
  local sel=0 key
  printf '\033[2J\033[H'
  tput civis 2>/dev/null || true
  _L "opened"
  _draw "$sel"

  while true; do
    IFS= read -rsn1 key </dev/tty
    case "$key" in
      $'\033')
        local seq1 seq2
        IFS= read -rsn1 -t 1 seq1 </dev/tty || true
        IFS= read -rsn1 -t 1 seq2 </dev/tty || true
        if [[ "$seq1" == "[" ]]; then
          case "$seq2" in
            A) (( sel = (sel - 1 + _N) % _N )); _draw "$sel" ;;  # ↑
            B) (( sel = (sel + 1) % _N )); _draw "$sel" ;;        # ↓
          esac
        else
          # Esc → chiudi palette
          tput cnorm 2>/dev/null || true; exit 0
        fi
        ;;
      k) (( sel = (sel - 1 + _N) % _N )); _draw "$sel" ;;
      j) (( sel = (sel + 1) % _N )); _draw "$sel" ;;
      $'\t') (( sel = (sel + 1) % _N )); _draw "$sel" ;;
      "")  # Enter
        _execute "$sel"
        ;;
      q)
        # q → chiudi BigIDE (kill session)
        tput cnorm 2>/dev/null || true
        tmux kill-session -t "$_SESSION" 2>/dev/null || tmux kill-session 2>/dev/null || true
        exit 0
        ;;
      *)
        # Tasto diretto: trova e lancia subito
        local i
        for i in "${!_ITEMS[@]}"; do
          local item_key="${_ITEMS[$i]%%|*}"
          if [[ "$key" == "$item_key" ]]; then
            _execute "$i"
            break
          fi
        done
        ;;
    esac
  done
}

_main

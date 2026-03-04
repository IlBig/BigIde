#!/usr/bin/env bash
# BigIDE — Provider Selector: sceglie tra Claude, Codex, Gemini
# Chiamato da tmux popup (es. prefix + m)
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

BIGIDE_HOME="${BIGIDE_HOME:-$HOME/.bigide}"

# ─── ERR trap per debug crash ─────────────────────────────────────────────────
trap 'printf "%s [ERR] runner-selector crash: line=%d cmd=%s\n" "$(date +%Y-%m-%d\ %H:%M:%S)" "$LINENO" "$BASH_COMMAND" >> "$BIGIDE_HOME/logs/bigide.log" 2>/dev/null || true' ERR

# ─── Auto-reload da repo ─────────────────────────────────────────────────────
_REPO_ROOT="$(cat "$BIGIDE_HOME/.repo_root" 2>/dev/null)" || true
if [[ -n "$_REPO_ROOT" ]]; then
  _REPO_SCRIPT="$_REPO_ROOT/config/scripts/runner-selector.sh"
  _SELF="${BASH_SOURCE[0]}"
  # Esegui sempre dal repo — il check -nt non funziona perché setup-runtime.sh
  # copia i file e aggiorna il mtime dell'installato rendendolo sempre "più recente"
  if [[ -f "$_REPO_SCRIPT" && "$_SELF" != "$_REPO_SCRIPT" ]]; then
    exec bash "$_REPO_SCRIPT" "$@"
  fi
  BIGIDE_REPO_ROOT="$_REPO_ROOT"
else
  BIGIDE_REPO_ROOT="__BIGIDE_REPO_ROOT__"
fi

# ─── Colori Tokyo Night ──────────────────────────────────────────────────────
_C_DIM=$'\033[38;2;86;95;137m'         # #565f89
_C_CYAN=$'\033[38;2;125;207;255m'      # #7dcfff
_C_WHITE=$'\033[38;2;192;202;245m'     # #c0caf5
_C_GREEN=$'\033[38;2;158;206;106m'     # #9ece6a
_C_VIOLET=$'\033[38;2;187;154;247m'    # #bb9af7
_C_BLUE=$'\033[38;2;122;162;247m'      # #7aa2f7
_C_FRAME=$'\033[38;2;59;66;97m'        # #3b4261
_C_RESET=$'\033[0m'

# ─── Helpers ──────────────────────────────────────────────────────────────────
_goto() { printf '\033[%d;%dH' "$1" "$2"; }
_detect_size() {
  local size
  if [[ -t 0 ]] && size=$(stty size 2>/dev/null) && [[ -n "$size" ]]; then
    TERM_H="${size%% *}"; TERM_W="${size##* }"
  else
    TERM_W="${COLUMNS:-80}"; TERM_H="${LINES:-24}"
  fi
}

# ─── Provider attivo ─────────────────────────────────────────────────────────
_get_active_runner() {
  # Per-window: leggi da tmux window option se disponibile
  if [[ -n "${BIGIDE_WINDOW:-}" ]]; then
    local wr
    wr="$(tmux show-option -wqv -t "$BIGIDE_WINDOW" @bigide_runner 2>/dev/null)" || true
    [[ -n "$wr" ]] && { echo "$wr"; return 0; }
  fi
  cat "$BIGIDE_HOME/active-runner" 2>/dev/null || echo "anthropic"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Menu provider
# ═══════════════════════════════════════════════════════════════════════════════

_menu() {
  # Provider: (display_label, runner_id, cli_name)
  local providers=(
    "Anthropic|anthropic|claude"
    "OpenAI|openai|codex"
    "Google|gemini|gemini"
  )
  local n_items=${#providers[@]}

  local active_runner
  active_runner="$(_get_active_runner)"

  # Pre-seleziona il provider attivo
  local sel=0
  for i in "${!providers[@]}"; do
    local runner_id="${providers[$i]%%|*}"
    runner_id="${providers[$i]#*|}"
    runner_id="${runner_id%%|*}"
    if [[ "$runner_id" == "$active_runner" ]]; then
      sel=$i
      break
    fi
  done

  _detect_size

  local box_w=40
  local box_total=$(( box_w + 2 ))
  local col=$(( (TERM_W - box_total) / 2 ))
  (( col < 1 )) && col=1 || true
  # Altezza: top(1) + vuota(1) + titolo(1) + vuota(1) + 3 items + vuota(1) + footer(1) + bottom(1) = 10
  local box_h=10
  local top=$(( (TERM_H - box_h) / 2 ))
  (( top < 1 )) && top=1 || true

  tput civis 2>/dev/null || true

  _draw() {
    local r=$top c=$col w=$box_w

    # Top border
    _goto "$r" "$c"
    printf '%s┌' "$_C_FRAME"
    printf '─%.0s' $(seq 1 "$w")
    printf '┐%s' "$_C_RESET"
    (( r++ ))

    # Vuota
    _goto "$r" "$c"; printf '%s│%*s│%s' "$_C_FRAME" "$w" "" "$_C_RESET"; (( r++ ))

    # Titolo
    local title="Seleziona Provider AI"
    local tpad=$(( (w - ${#title}) / 2 ))
    _goto "$r" "$c"
    printf '%s│%*s%s%s%*s%s│%s' \
      "$_C_FRAME" "$tpad" "" "$_C_VIOLET" "$title" $(( w - tpad - ${#title} )) "" "$_C_FRAME" "$_C_RESET"
    (( r++ ))

    # Vuota
    _goto "$r" "$c"; printf '%s│%*s│%s' "$_C_FRAME" "$w" "" "$_C_RESET"; (( r++ ))

    # Items
    local opad=6
    for i in "${!providers[@]}"; do
      local entry="${providers[$i]}"
      local display="${entry%%|*}"
      local rest="${entry#*|}"
      local runner_id="${rest%%|*}"
      local cli="${rest#*|}"

      local mark color active_mark=""
      if [[ "$runner_id" == "$active_runner" ]]; then
        active_mark=" ${_C_GREEN}●${_C_RESET}"
      fi
      if (( i == sel )); then
        mark="▸ "; color="$_C_CYAN"
      else
        mark="  "; color="$_C_WHITE"
      fi

      local label="${mark}${display}"
      local active_visual=0
      [[ -n "$active_mark" ]] && active_visual=2
      local pad=$(( w - opad - ${#label} - active_visual ))
      (( pad < 0 )) && pad=0

      _goto "$r" "$c"
      printf '%s│%*s%s%s%*s%s%s│%s' \
        "$_C_FRAME" "$opad" "" "$color" "$label" "$pad" "" \
        "${active_mark}" "$_C_FRAME" "$_C_RESET"
      (( r++ ))
    done

    # Vuota
    _goto "$r" "$c"; printf '%s│%*s│%s' "$_C_FRAME" "$w" "" "$_C_RESET"; (( r++ ))

    # Footer
    local hint="↑↓ naviga  Enter seleziona  Esc esci"
    local hpad=$(( (w - ${#hint}) / 2 ))
    _goto "$r" "$c"
    printf '%s│%*s%s%s%*s%s│%s' \
      "$_C_FRAME" "$hpad" "" "$_C_DIM" "$hint" $(( w - hpad - ${#hint} )) "" "$_C_FRAME" "$_C_RESET"
    (( r++ ))

    # Bottom border
    _goto "$r" "$c"
    printf '%s└' "$_C_FRAME"
    printf '─%.0s' $(seq 1 "$w")
    printf '┘%s' "$_C_RESET"
  }

  printf '\033[2J\033[H'
  _draw

  local key
  while true; do
    IFS= read -rsn1 key </dev/tty
    case "$key" in
      $'\033')
        local seq1 seq2
        IFS= read -rsn1 -t 1 seq1 </dev/tty || true
        IFS= read -rsn1 -t 1 seq2 </dev/tty || true
        if [[ "$seq1" == "[" ]]; then
          case "$seq2" in
            A) (( sel = (sel - 1 + n_items) % n_items )); _draw ;;
            B) (( sel = (sel + 1) % n_items )); _draw ;;
          esac
        else
          tput cnorm 2>/dev/null || true; exit 0
        fi
        ;;
      k) (( sel = (sel - 1 + n_items) % n_items )); _draw ;;
      j) (( sel = (sel + 1) % n_items )); _draw ;;
      $'\t') (( sel = (sel + 1) % n_items )); _draw ;;
      "")  # Enter
        local chosen="${providers[$sel]}"
        local chosen_display="${chosen%%|*}"
        local chosen_rest="${chosen#*|}"
        local chosen_runner="${chosen_rest%%|*}"
        _apply_selection "$chosen_runner" "$chosen_display"
        tput cnorm 2>/dev/null || true
        exit 0
        ;;
      q) tput cnorm 2>/dev/null || true; exit 0 ;;
    esac
  done
}

# ═══════════════════════════════════════════════════════════════════════════════
# Applica selezione — salva provider e riavvia CLI nativa
# ═══════════════════════════════════════════════════════════════════════════════

_apply_selection() {
  local runner="$1" display="$2"

  mkdir -p "$BIGIDE_HOME"
  # Globale (persistenza e fallback)
  echo "$runner" > "$BIGIDE_HOME/active-runner"

  # Per-window: scrivi runner + display name sul window corrente
  if [[ -n "${BIGIDE_WINDOW:-}" ]]; then
    tmux set-option -w -t "$BIGIDE_WINDOW" @bigide_runner "$runner" 2>/dev/null || true
    local disp_name
    case "$runner" in
      anthropic) disp_name="claude" ;;
      openai)    disp_name="codex" ;;
      gemini)    disp_name="gemini" ;;
      *)         disp_name="$runner" ;;
    esac
    tmux set-option -w -t "$BIGIDE_WINDOW" @bigide_runner_display "$disp_name" 2>/dev/null || true
  fi

  printf '%s [EVENT] provider-change → %s (%s)\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$runner" "$display" >> "$BIGIDE_HOME/logs/bigide.log" 2>/dev/null || true

  _restart_provider

  printf '\033[2J\033[H'
  echo
  echo "  ${_C_GREEN}✓${_C_RESET} Provider: ${_C_CYAN}${display}${_C_RESET}"
  echo
  echo "  ${_C_DIM}Avvio in corso...${_C_RESET}"
  echo
  sleep 1.0
}

# ═══════════════════════════════════════════════════════════════════════════════
# Riavvia la CLI nel pane tmux
# ═══════════════════════════════════════════════════════════════════════════════

_restart_provider() {
  printf '%s [DEBUG] _restart_provider: CALLED win=%s\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "${BIGIDE_WINDOW:-}" \
    >> "$BIGIDE_HOME/logs/bigide.log" 2>/dev/null || true

  local claude_pane

  # Scope al window corrente se disponibile, altrimenti fallback globale
  if [[ -n "${BIGIDE_WINDOW:-}" ]]; then
    claude_pane=$(tmux list-panes -t "$BIGIDE_WINDOW" -F '#{pane_id} #{@bigide_pane_type}' 2>/dev/null \
      | awk '$2 == "claude" {print $1; exit}')
  else
    claude_pane=$(tmux list-panes -a -F '#{pane_id} #{@bigide_pane_type}' 2>/dev/null \
      | awk '$2 == "claude" {print $1; exit}')
  fi

  # Log diagnostico: mostra tutti i pane con il loro tipo
  local _pane_dump
  _pane_dump="$(tmux list-panes -t "${BIGIDE_WINDOW:-}" -F '#{pane_id}:#{@bigide_pane_type}' 2>/dev/null | tr '\n' ' ')" || _pane_dump="ERR"
  printf '%s [DEBUG] restart_provider: window=%s panes=[%s] found=%s\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "${BIGIDE_WINDOW:-}" "$_pane_dump" "$claude_pane" \
    >> "$BIGIDE_HOME/logs/bigide.log" 2>/dev/null || true

  if [[ -z "$claude_pane" ]]; then
    printf '%s [WARN] restart_provider: nessun pane claude (window=%s)\n' \
      "$(date '+%Y-%m-%d %H:%M:%S')" "${BIGIDE_WINDOW:-}" >> "$BIGIDE_HOME/logs/bigide.log" 2>/dev/null || true
    return 0
  fi

  # Project path: per-window → fallback globale
  local project_path=""
  if [[ -n "${BIGIDE_WINDOW:-}" ]]; then
    project_path="$(tmux show-option -wqv -t "$BIGIDE_WINDOW" @bigide_project_path 2>/dev/null)" || true
  fi
  [[ -z "$project_path" ]] && project_path="$(cat "$BIGIDE_HOME/active-project-path" 2>/dev/null)" || true
  project_path="${project_path/#\~/$HOME}"

  printf '%s [PANE] restart_provider: pane=%s path=%s win=%s\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$claude_pane" "$project_path" "${BIGIDE_WINDOW:-}" \
    >> "$BIGIDE_HOME/logs/bigide.log" 2>/dev/null || true

  # Script temporaneo: evita race condition tra respawn-pane e send-keys
  # (la shell impiega 1-2s ad inizializzare; send-keys arriverebbe nel vuoto)
  mkdir -p "$BIGIDE_HOME/tmp"
  local tmpscript
  tmpscript="$(mktemp "$BIGIDE_HOME/tmp/restart-XXXXXX.sh")"
  {
    printf '#!/usr/bin/env bash\n'
    printf 'export BIGIDE_WINDOW=%q\n' "${BIGIDE_WINDOW:-}"
    [[ -n "$project_path" ]] && printf 'cd %q\n' "$project_path"
    printf 'clear\n'
    printf 'exec %q\n' "$HOME/.bigide/scripts/launch-claude.sh"
  } > "$tmpscript"
  chmod +x "$tmpscript"

  # respawn-pane con comando esplicito: nessun send-keys, nessun sleep
  local _respawn_out
  _respawn_out="$(tmux respawn-pane -k -t "$claude_pane" \
    "bash $(printf '%q' "$tmpscript"); rm -f $(printf '%q' "$tmpscript"); exec zsh -l" 2>&1)"
  printf '%s [PANE] respawn-pane exit=%d out=%s script=%s\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$?" "$_respawn_out" "$tmpscript" \
    >> "$BIGIDE_HOME/logs/bigide.log" 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════════════════════

_menu

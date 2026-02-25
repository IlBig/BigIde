#!/usr/bin/env bash
# BigIDE — Runner Selector: login provider + selezione modello AI
# Chiamato da tmux popup (es. prefix + m)
# Due fasi: 1) Configura Provider  2) Seleziona Modello/Runner
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

BIGIDE_HOME="${BIGIDE_HOME:-$HOME/.bigide}"
RUNNERS_DIR="$BIGIDE_HOME/runners"

# ─── Auto-reload da repo ─────────────────────────────────────────────────────
_REPO_ROOT="$(cat "$BIGIDE_HOME/.repo_root" 2>/dev/null)" || true
if [[ -n "$_REPO_ROOT" ]]; then
  _REPO_SCRIPT="$_REPO_ROOT/config/scripts/runner-selector.sh"
  _SELF="${BASH_SOURCE[0]}"
  if [[ -f "$_REPO_SCRIPT" && "$_SELF" != "$_REPO_SCRIPT" && "$_REPO_SCRIPT" -nt "$_SELF" ]]; then
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
_C_RED=$'\033[38;2;247;118;142m'       # #f7768e
_C_ORANGE=$'\033[38;2;255;158;100m'    # #ff9e64
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

# ─── Stato provider ──────────────────────────────────────────────────────────
_check_provider() {
  local script="$BIGIDE_REPO_ROOT/config/scripts/oauth-${1}.mjs"
  [[ -f "$script" ]] && node "$script" ensure 2>/dev/null
}

_provider_status() {
  if _check_provider "$1"; then
    echo "connected"
  else
    echo "disconnected"
  fi
}

# ─── Stato attivo (runner + modello) ──────────────────────────────────────────

_get_active_key() {
  # Ritorna "runner:model" come chiave unica per confronto
  local runner model
  runner="$(cat "$BIGIDE_HOME/active-runner" 2>/dev/null)" || runner="anthropic"
  model="$(cat "$BIGIDE_HOME/active-model" 2>/dev/null)" || model="sonnet"
  echo "${runner}:${model}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# FASE 1 — Configura Provider
# ═══════════════════════════════════════════════════════════════════════════════

_phase1() {
  local sel=0
  local n_items=4  # 3 provider + Continua

  # Carica status
  local status_claude status_openai status_gemini
  status_claude="$(_provider_status claude)"
  status_openai="$(_provider_status openai)"
  status_gemini="$(_provider_status gemini)"

  _detect_size

  local box_w=52
  local box_total=$(( box_w + 2 ))
  local col=$(( (TERM_W - box_total) / 2 ))
  (( col < 1 )) && col=1 || true
  local box_h=14
  local top=$(( (TERM_H - box_h) / 2 ))
  (( top < 1 )) && top=1 || true

  tput civis 2>/dev/null || true

  _p1_draw() {
    local r=$top c=$col w=$box_w

    # Cornice top
    _goto "$r" "$c"
    printf '%s┌' "$_C_FRAME"
    printf '─%.0s' $(seq 1 "$w")
    printf '┐%s' "$_C_RESET"
    (( r++ ))

    # Riga vuota
    _goto "$r" "$c"; printf '%s│%*s│%s' "$_C_FRAME" "$w" "" "$_C_RESET"; (( r++ ))

    # Titolo
    local title="Configura Provider AI"
    local tpad=$(( (w - ${#title}) / 2 ))
    _goto "$r" "$c"; printf '%s│%*s%s%s%*s%s│%s' \
      "$_C_FRAME" "$tpad" "" "$_C_VIOLET" "$title" $(( w - tpad - ${#title} )) "" "$_C_FRAME" "$_C_RESET"
    (( r++ ))

    # Riga vuota
    _goto "$r" "$c"; printf '%s│%*s│%s' "$_C_FRAME" "$w" "" "$_C_RESET"; (( r++ ))

    # ── Provider: Anthropic ──
    local lbl mark color badge_text badge_color opad=5
    lbl="Anthropic (Claude MAX)"
    badge_text="$([[ "$status_claude" == "connected" ]] && echo "✓ connesso" || echo "✗ da collegare")"
    badge_color="$([[ "$status_claude" == "connected" ]] && printf '%s' "$_C_GREEN" || printf '%s' "$_C_RED")"
    if (( sel == 0 )); then mark="▸ "; color="$_C_CYAN"; else mark="  "; color="$_C_DIM"; fi
    _goto "$r" "$c"
    printf '%s│%*s%s%s%s%-24s %s%s%*s%s│%s' \
      "$_C_FRAME" "$opad" "" "$color" "$mark" "$_C_WHITE" "$lbl" \
      "$badge_color" "$badge_text" $(( w - opad - 2 - 24 - 1 - ${#badge_text} )) "" "$_C_FRAME" "$_C_RESET"
    (( r++ ))

    # ── Provider: OpenAI ──
    lbl="OpenAI (Codex)"
    badge_text="$([[ "$status_openai" == "connected" ]] && echo "✓ connesso" || echo "✗ da collegare")"
    badge_color="$([[ "$status_openai" == "connected" ]] && printf '%s' "$_C_GREEN" || printf '%s' "$_C_RED")"
    if (( sel == 1 )); then mark="▸ "; color="$_C_CYAN"; else mark="  "; color="$_C_DIM"; fi
    _goto "$r" "$c"
    printf '%s│%*s%s%s%s%-24s %s%s%*s%s│%s' \
      "$_C_FRAME" "$opad" "" "$color" "$mark" "$_C_WHITE" "$lbl" \
      "$badge_color" "$badge_text" $(( w - opad - 2 - 24 - 1 - ${#badge_text} )) "" "$_C_FRAME" "$_C_RESET"
    (( r++ ))

    # ── Provider: Gemini ──
    lbl="Google (Gemini)"
    badge_text="$([[ "$status_gemini" == "connected" ]] && echo "✓ connesso" || echo "✗ da collegare")"
    badge_color="$([[ "$status_gemini" == "connected" ]] && printf '%s' "$_C_GREEN" || printf '%s' "$_C_RED")"
    if (( sel == 2 )); then mark="▸ "; color="$_C_CYAN"; else mark="  "; color="$_C_DIM"; fi
    _goto "$r" "$c"
    printf '%s│%*s%s%s%s%-24s %s%s%*s%s│%s' \
      "$_C_FRAME" "$opad" "" "$color" "$mark" "$_C_WHITE" "$lbl" \
      "$badge_color" "$badge_text" $(( w - opad - 2 - 24 - 1 - ${#badge_text} )) "" "$_C_FRAME" "$_C_RESET"
    (( r++ ))

    # Riga vuota
    _goto "$r" "$c"; printf '%s│%*s│%s' "$_C_FRAME" "$w" "" "$_C_RESET"; (( r++ ))

    # Separatore
    local sep_w=$(( w - 10 ))
    _goto "$r" "$c"
    printf '%s│%5s' "$_C_FRAME" ""
    printf '%s' "$_C_DIM"
    printf '─%.0s' $(seq 1 "$sep_w")
    printf '%5s%s│%s' "" "$_C_FRAME" "$_C_RESET"
    (( r++ ))

    # ── Continua ──
    local clbl
    if (( sel == 3 )); then
      clbl="▸ Seleziona Modello ▸"
      color="$_C_ORANGE"
    else
      clbl="  Seleziona Modello ▸"
      color="$_C_DIM"
    fi
    local cpad=$(( (w - ${#clbl}) / 2 ))
    _goto "$r" "$c"
    printf '%s│%*s%s%s%*s%s│%s' \
      "$_C_FRAME" "$cpad" "" "$color" "$clbl" $(( w - cpad - ${#clbl} )) "" "$_C_FRAME" "$_C_RESET"
    (( r++ ))

    # Riga vuota
    _goto "$r" "$c"; printf '%s│%*s│%s' "$_C_FRAME" "$w" "" "$_C_RESET"; (( r++ ))

    # Footer hint
    local hint="↑↓ naviga  Enter seleziona  Esc esci"
    local hpad=$(( (w - ${#hint}) / 2 ))
    _goto "$r" "$c"
    printf '%s│%*s%s%s%*s%s│%s' \
      "$_C_FRAME" "$hpad" "" "$_C_DIM" "$hint" $(( w - hpad - ${#hint} )) "" "$_C_FRAME" "$_C_RESET"
    (( r++ ))

    # Cornice bottom
    _goto "$r" "$c"
    printf '%s└' "$_C_FRAME"
    printf '─%.0s' $(seq 1 "$w")
    printf '┘%s' "$_C_RESET"
  }

  printf '\033[2J\033[H'
  _p1_draw

  local key
  while true; do
    IFS= read -rsn1 key </dev/tty
    case "$key" in
      $'\033')
        local seq1 seq2
        IFS= read -rsn1 -t 0.05 seq1 </dev/tty || true
        IFS= read -rsn1 -t 0.05 seq2 </dev/tty || true
        if [[ "$seq1" == "[" ]]; then
          case "$seq2" in
            A) (( sel = (sel - 1 + n_items) % n_items )); _p1_draw ;;  # ↑
            B) (( sel = (sel + 1) % n_items )); _p1_draw ;;            # ↓
          esac
        else
          tput cnorm 2>/dev/null || true; exit 0  # Esc
        fi
        ;;
      k) (( sel = (sel - 1 + n_items) % n_items )); _p1_draw ;;
      j) (( sel = (sel + 1) % n_items )); _p1_draw ;;
      $'\t') (( sel = (sel + 1) % n_items )); _p1_draw ;;
      "")  # Enter
        case "$sel" in
          0)  # Login Anthropic
            printf '\033[2J\033[H'
            tput cnorm 2>/dev/null || true
            node "$BIGIDE_REPO_ROOT/config/scripts/oauth-claude.mjs" login </dev/tty || true
            echo; echo "Premi un tasto per tornare al menu..."
            IFS= read -rsn1 </dev/tty
            status_claude="$(_provider_status claude)"
            tput civis 2>/dev/null || true
            printf '\033[2J\033[H'
            _p1_draw
            ;;
          1)  # Login OpenAI
            printf '\033[2J\033[H'
            tput cnorm 2>/dev/null || true
            node "$BIGIDE_REPO_ROOT/config/scripts/oauth-openai.mjs" login </dev/tty || true
            echo; echo "Premi un tasto per tornare al menu..."
            IFS= read -rsn1 </dev/tty
            status_openai="$(_provider_status openai)"
            tput civis 2>/dev/null || true
            printf '\033[2J\033[H'
            _p1_draw
            ;;
          2)  # Login Gemini
            printf '\033[2J\033[H'
            tput cnorm 2>/dev/null || true
            node "$BIGIDE_REPO_ROOT/config/scripts/oauth-gemini.mjs" login </dev/tty || true
            echo; echo "Premi un tasto per tornare al menu..."
            IFS= read -rsn1 </dev/tty
            status_gemini="$(_provider_status gemini)"
            tput civis 2>/dev/null || true
            printf '\033[2J\033[H'
            _p1_draw
            ;;
          3)  # Continua → Fase 2
            tput cnorm 2>/dev/null || true
            _phase2 "$status_claude"
            return $?
            ;;
        esac
        ;;
      q) tput cnorm 2>/dev/null || true; exit 0 ;;
    esac
  done
}

# ═══════════════════════════════════════════════════════════════════════════════
# FASE 2 — Seleziona Modello / Runner
# ═══════════════════════════════════════════════════════════════════════════════

_phase2() {
  local st_claude="${1:-disconnected}"

  local active_key
  active_key="$(_get_active_key)"

  # Costruisci lista: (tipo|display|item_key|action_type)
  #   item_key = "anthropic:<alias>" o "custom:<runner_name>"
  #   action_type = "anthropic" o "custom"
  local items=()

  # ── Modelli Anthropic (nativi, --model flag) ──
  if [[ "$st_claude" == "connected" ]]; then
    items+=("header|── Anthropic (Claude MAX) ────────────")
    items+=("model|Sonnet 4.6|anthropic:sonnet|anthropic")
    items+=("model|Opus 4.6|anthropic:opus|anthropic")
    items+=("model|Haiku 4.5|anthropic:haiku|anthropic")
    items+=("model|OpusPlan (opus+sonnet)|anthropic:opusplan|anthropic")
  fi

  # ── Runner custom (CLAUDE_CONFIG_DIR) ──
  local has_custom=false
  if [[ -d "$RUNNERS_DIR" ]]; then
    for rdir in "$RUNNERS_DIR"/*/; do
      [[ -f "${rdir}settings.json" ]] || continue
      has_custom=true
      local rname
      rname="$(basename "$rdir")"
      # Estrai modello dal settings.json per display
      local rmodel
      rmodel="$(jq -r '.env.ANTHROPIC_MODEL // "n/a"' "${rdir}settings.json" 2>/dev/null)" || rmodel="n/a"
      items+=("model|${rname} (${rmodel})|custom:${rname}|custom")
    done
  fi

  if [[ "$has_custom" == true ]]; then
    # Inserisci header custom prima dei runner custom
    # Trova l'indice del primo runner custom e inserisci l'header
    local new_items=()
    local inserted=false
    for entry in "${items[@]}"; do
      if [[ "$inserted" == false && "$entry" == model*custom ]]; then
        new_items+=("header|── Runner Custom ────────────────────")
        inserted=true
      fi
      new_items+=("$entry")
    done
    items=("${new_items[@]}")
  fi

  items+=("header|────────────────────────────────────────")
  items+=("model|◂ Torna ai provider|_back|_back")

  # Se nessun provider e nessun runner custom
  if [[ "$st_claude" != "connected" && "$has_custom" != true ]]; then
    items=()
    items+=("header|  Nessun provider connesso!")
    items+=("header|  Torna indietro e fai login.")
    items+=("header|────────────────────────────────────────")
    items+=("model|◂ Torna ai provider|_back|_back")
  fi

  # Indici selezionabili (solo model, non header)
  local selectable=()
  for i in "${!items[@]}"; do
    local type="${items[$i]%%|*}"
    if [[ "$type" == "model" ]]; then
      selectable+=("$i")
    fi
  done

  local sel_idx=0  # indice dentro selectable[]
  local n_sel=${#selectable[@]}

  # Pre-seleziona modello attivo
  if [[ -n "$active_key" ]]; then
    for si in "${!selectable[@]}"; do
      local entry="${items[${selectable[$si]}]}"
      local rest="${entry#*|}"
      local tmp="${rest#*|}"
      local item_key="${tmp%%|*}"
      if [[ "$item_key" == "$active_key" ]]; then
        sel_idx=$si
        break
      fi
    done
  fi

  _detect_size

  local box_w=48
  local box_total=$(( box_w + 2 ))
  local col=$(( (TERM_W - box_total) / 2 ))
  (( col < 1 )) && col=1 || true
  local box_h=$(( ${#items[@]} + 6 ))
  local top=$(( (TERM_H - box_h) / 2 ))
  (( top < 1 )) && top=1 || true

  tput civis 2>/dev/null || true

  _p2_draw() {
    local r=$top c=$col w=$box_w
    local cur_item=${selectable[$sel_idx]}

    # Top
    _goto "$r" "$c"
    printf '%s┌' "$_C_FRAME"
    printf '─%.0s' $(seq 1 "$w")
    printf '┐%s' "$_C_RESET"
    (( r++ ))

    # Vuota
    _goto "$r" "$c"; printf '%s│%*s│%s' "$_C_FRAME" "$w" "" "$_C_RESET"; (( r++ ))

    # Titolo
    local title="Seleziona Modello"
    local tpad=$(( (w - ${#title}) / 2 ))
    _goto "$r" "$c"
    printf '%s│%*s%s%s%*s%s│%s' \
      "$_C_FRAME" "$tpad" "" "$_C_VIOLET" "$title" $(( w - tpad - ${#title} )) "" "$_C_FRAME" "$_C_RESET"
    (( r++ ))

    # Vuota
    _goto "$r" "$c"; printf '%s│%*s│%s' "$_C_FRAME" "$w" "" "$_C_RESET"; (( r++ ))

    # Items
    local opad=4
    for i in "${!items[@]}"; do
      local entry="${items[$i]}"
      local type="${entry%%|*}"
      local rest="${entry#*|}"

      _goto "$r" "$c"

      if [[ "$type" == "header" ]]; then
        local htext="$rest"
        printf '%s│%*s%s%s%*s%s│%s' \
          "$_C_FRAME" "$opad" "" "$_C_DIM" "$htext" $(( w - opad - ${#htext} )) "" "$_C_FRAME" "$_C_RESET"
      else
        # Model selezionabile
        local display="${rest%%|*}"
        local tmp2="${rest#*|}"
        local item_key="${tmp2%%|*}"
        local mark color active_mark=""

        # Segna modello attivo
        if [[ -n "$active_key" && "$item_key" == "$active_key" ]]; then
          active_mark=" ${_C_GREEN}●${_C_RESET}"
        fi

        if (( i == cur_item )); then
          mark="▸ "; color="$_C_CYAN"
        else
          mark="  "; color="$_C_WHITE"
        fi

        local label="${mark}${display}"
        local label_len=${#label}
        local active_visual=0
        if [[ -n "$active_mark" ]]; then
          active_visual=2  # spazio + ●
        fi
        local pad=$(( w - opad - label_len - active_visual ))
        (( pad < 0 )) && pad=0 || true

        printf '%s│%*s%s%s%*s%s%s│%s' \
          "$_C_FRAME" "$opad" "" "$color" "$label" "$pad" "" "$active_mark" "$_C_FRAME" "$_C_RESET"
      fi
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

    # Bottom
    _goto "$r" "$c"
    printf '%s└' "$_C_FRAME"
    printf '─%.0s' $(seq 1 "$w")
    printf '┘%s' "$_C_RESET"
  }

  printf '\033[2J\033[H'
  _p2_draw

  local key
  while true; do
    IFS= read -rsn1 key </dev/tty
    case "$key" in
      $'\033')
        local seq1 seq2
        IFS= read -rsn1 -t 0.05 seq1 </dev/tty || true
        IFS= read -rsn1 -t 0.05 seq2 </dev/tty || true
        if [[ "$seq1" == "[" ]]; then
          case "$seq2" in
            A) (( sel_idx = (sel_idx - 1 + n_sel) % n_sel )); _p2_draw ;;
            B) (( sel_idx = (sel_idx + 1) % n_sel )); _p2_draw ;;
          esac
        else
          tput cnorm 2>/dev/null || true; exit 0
        fi
        ;;
      k) (( sel_idx = (sel_idx - 1 + n_sel) % n_sel )); _p2_draw ;;
      j) (( sel_idx = (sel_idx + 1) % n_sel )); _p2_draw ;;
      $'\t') (( sel_idx = (sel_idx + 1) % n_sel )); _p2_draw ;;
      "")  # Enter
        local chosen_entry="${items[${selectable[$sel_idx]}]}"
        local chosen_rest="${chosen_entry#*|}"
        local chosen_display="${chosen_rest%%|*}"
        local tmp="${chosen_rest#*|}"
        local chosen_key="${tmp%%|*}"
        local chosen_type="${tmp#*|}"

        if [[ "$chosen_key" == "_back" ]]; then
          tput cnorm 2>/dev/null || true
          _phase1
          return $?
        fi

        _apply_selection "$chosen_key" "$chosen_type" "$chosen_display"
        tput cnorm 2>/dev/null || true
        exit 0
        ;;
      q) tput cnorm 2>/dev/null || true; exit 0 ;;
    esac
  done
}

# ═══════════════════════════════════════════════════════════════════════════════
# Applica selezione — salva runner + modello e riavvia Claude
# ═══════════════════════════════════════════════════════════════════════════════

_apply_selection() {
  local item_key="$1" action_type="$2" display="$3"

  mkdir -p "$BIGIDE_HOME"

  if [[ "$action_type" == "anthropic" ]]; then
    # item_key = "anthropic:<alias>" → es. "anthropic:sonnet"
    local alias="${item_key#anthropic:}"
    echo "anthropic" > "$BIGIDE_HOME/active-runner"
    echo "$alias"    > "$BIGIDE_HOME/active-model"
  else
    # item_key = "custom:<runner_name>" → es. "custom:kimi"
    local runner_name="${item_key#custom:}"
    local rmodel
    rmodel="$(jq -r '.env.ANTHROPIC_MODEL // "unknown"' "$RUNNERS_DIR/$runner_name/settings.json" 2>/dev/null)" || rmodel="unknown"
    echo "$runner_name" > "$BIGIDE_HOME/active-runner"
    echo "$rmodel"      > "$BIGIDE_HOME/active-model"
  fi

  # Riavvia Claude nel pane tmux
  _restart_claude_resume

  # Feedback visivo
  printf '\033[2J\033[H'
  echo
  echo "  ${_C_GREEN}✓${_C_RESET} Selezionato: ${_C_CYAN}${display}${_C_RESET}"
  echo
  echo "  ${_C_DIM}Claude Code si sta riavviando con --resume...${_C_RESET}"
  echo
  sleep 1.2
}

# ═══════════════════════════════════════════════════════════════════════════════
# Riavvia Claude Code nel pane tmux con --resume
# ═══════════════════════════════════════════════════════════════════════════════

_restart_claude_resume() {
  # Trova il pane di Claude tramite il marker @bigide_pane_type
  local claude_pane
  claude_pane=$(tmux list-panes -a -F '#{pane_id} #{@bigide_pane_type}' 2>/dev/null \
    | awk '$2 == "claude" {print $1; exit}')

  if [[ -z "$claude_pane" ]]; then
    return 0  # Nessun pane Claude trovato, niente da riavviare
  fi

  # respawn-pane -k: uccide il processo corrente e avvia una nuova shell
  tmux respawn-pane -k -t "$claude_pane" 2>/dev/null || true
  sleep 0.4

  # Rilancia Claude con --resume nella nuova shell
  tmux send-keys -t "$claude_pane" 'clear; $HOME/.bigide/scripts/launch-claude.sh --resume' C-m
}

# ═══════════════════════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════════════════════

_phase1

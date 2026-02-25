#!/usr/bin/env bash
# BigIDE — Runner Selector: login provider + selezione modello AI
# Chiamato da tmux popup (es. prefix + m)
# Due fasi: 1) Configura Provider  2) Seleziona Modello
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

BIGIDE_HOME="${BIGIDE_HOME:-$HOME/.bigide}"

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

  _p1_status_badge() {
    if [[ "$1" == "connected" ]]; then
      printf '%s✓ connesso%s' "$_C_GREEN" "$_C_RESET"
    else
      printf '%s✗ non connesso%s' "$_C_RED" "$_C_RESET"
    fi
  }

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
    local lbl mark color badge opad=5
    lbl="Anthropic (Claude MAX)"
    badge_claude="$([[ "$status_claude" == "connected" ]] && echo "✓ connesso" || echo "✗ da collegare")"
    badge_color="$([[ "$status_claude" == "connected" ]] && printf '%s' "$_C_GREEN" || printf '%s' "$_C_RED")"
    if (( sel == 0 )); then mark="▸ "; color="$_C_CYAN"; else mark="  "; color="$_C_DIM"; fi
    _goto "$r" "$c"
    printf '%s│%*s%s%s%s%-24s %s%s%*s%s│%s' \
      "$_C_FRAME" "$opad" "" "$color" "$mark" "$_C_WHITE" "$lbl" \
      "$badge_color" "$badge_claude" $(( w - opad - 2 - 24 - 1 - ${#badge_claude} )) "" "$_C_FRAME" "$_C_RESET"
    (( r++ ))

    # ── Provider: OpenAI ──
    lbl="OpenAI (Codex)"
    badge_openai="$([[ "$status_openai" == "connected" ]] && echo "✓ connesso" || echo "✗ da collegare")"
    badge_color="$([[ "$status_openai" == "connected" ]] && printf '%s' "$_C_GREEN" || printf '%s' "$_C_RED")"
    if (( sel == 1 )); then mark="▸ "; color="$_C_CYAN"; else mark="  "; color="$_C_DIM"; fi
    _goto "$r" "$c"
    printf '%s│%*s%s%s%s%-24s %s%s%*s%s│%s' \
      "$_C_FRAME" "$opad" "" "$color" "$mark" "$_C_WHITE" "$lbl" \
      "$badge_color" "$badge_openai" $(( w - opad - 2 - 24 - 1 - ${#badge_openai} )) "" "$_C_FRAME" "$_C_RESET"
    (( r++ ))

    # ── Provider: Gemini ──
    lbl="Google (Gemini)"
    badge_gemini="$([[ "$status_gemini" == "connected" ]] && echo "✓ connesso" || echo "✗ da collegare")"
    badge_color="$([[ "$status_gemini" == "connected" ]] && printf '%s' "$_C_GREEN" || printf '%s' "$_C_RED")"
    if (( sel == 2 )); then mark="▸ "; color="$_C_CYAN"; else mark="  "; color="$_C_DIM"; fi
    _goto "$r" "$c"
    printf '%s│%*s%s%s%s%-24s %s%s%*s%s│%s' \
      "$_C_FRAME" "$opad" "" "$color" "$mark" "$_C_WHITE" "$lbl" \
      "$badge_color" "$badge_gemini" $(( w - opad - 2 - 24 - 1 - ${#badge_gemini} )) "" "$_C_FRAME" "$_C_RESET"
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
            _phase2 "$status_claude" "$status_openai" "$status_gemini"
            return $?
            ;;
        esac
        ;;
      q) tput cnorm 2>/dev/null || true; exit 0 ;;
    esac
  done
}

# ═══════════════════════════════════════════════════════════════════════════════
# FASE 2 — Seleziona Modello
# ═══════════════════════════════════════════════════════════════════════════════

_phase2() {
  local st_claude="${1:-disconnected}"
  local st_openai="${2:-disconnected}"
  local st_gemini="${3:-disconnected}"

  # Costruisci lista modelli: (tipo, display, model_id, provider_litellm)
  # Tipi: "header" (non selezionabile) o "model" (selezionabile)
  local items=()

  # Claude MAX — sempre disponibile (è il provider principale di Claude Code)
  items+=("header|── Claude MAX ─────────────────────")
  items+=("model|claude-sonnet-4-5  (default)|anthropic/claude-sonnet-4-5-20250929|anthropic")
  items+=("model|claude-opus-4-5|anthropic/claude-opus-4-5-20251101|anthropic")
  items+=("model|claude-haiku-4-5|anthropic/claude-haiku-4-5-20251001|anthropic")

  if [[ "$st_openai" == "connected" ]]; then
    items+=("header|── OpenAI Codex ────────────────────")
    items+=("model|gpt-5.3-codex|openai/gpt-5.3-codex|openai")
    items+=("model|gpt-5.1-codex-mini|openai/gpt-5.1-codex-mini|openai")
    items+=("model|gpt-4o|openai/gpt-4o|openai")
  fi

  if [[ "$st_gemini" == "connected" ]]; then
    items+=("header|── Google Gemini ────────────────────")
    items+=("model|gemini-2.5-pro|vertex_ai/gemini-2.5-pro|google")
    items+=("model|gemini-2.0-flash|vertex_ai/gemini-2.0-flash|google")
  fi

  items+=("header|────────────────────────────────────")
  items+=("model|◂ Torna ai provider|_back|_back")

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

  _detect_size

  local box_w=46
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
    local title="Seleziona Runner AI"
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
        # Header non selezionabile
        local htext="$rest"
        _goto "$r" "$c"
        printf '%s│%*s%s%s%*s%s│%s' \
          "$_C_FRAME" "$opad" "" "$_C_DIM" "$htext" $(( w - opad - ${#htext} )) "" "$_C_FRAME" "$_C_RESET"
      else
        # Model selezionabile
        local display="${rest%%|*}"
        local mark color
        if (( i == cur_item )); then
          mark="▸ "; color="$_C_CYAN"
        else
          mark="  "; color="$_C_DIM"
        fi
        local full="${mark}${display}"
        printf '%s│%*s%s%s%*s%s│%s' \
          "$_C_FRAME" "$opad" "" "$color" "$full" $(( w - opad - ${#full} )) "" "$_C_FRAME" "$_C_RESET"
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
        local chosen_model="${tmp%%|*}"
        local chosen_provider="${tmp#*|}"

        if [[ "$chosen_model" == "_back" ]]; then
          # Torna a fase 1
          tput cnorm 2>/dev/null || true
          _phase1
          return $?
        fi

        # Salva selezione modello
        _apply_model "$chosen_model" "$chosen_provider" "$chosen_display"
        tput cnorm 2>/dev/null || true
        exit 0
        ;;
      q) tput cnorm 2>/dev/null || true; exit 0 ;;
    esac
  done
}

# ═══════════════════════════════════════════════════════════════════════════════
# Applica modello selezionato — aggiorna config ccproxy
# ═══════════════════════════════════════════════════════════════════════════════

_apply_model() {
  local model="$1" provider="$2" display="$3"
  local ccproxy_config="$HOME/.ccproxy/config.yaml"

  # Salva scelta in config BigIDE
  local bigide_config="$BIGIDE_HOME/config.json"
  if [[ -f "$bigide_config" ]] && command -v jq &>/dev/null; then
    local tmp
    tmp="$(jq --arg m "$model" --arg p "$provider" --arg d "$display" \
      '.ccproxy.activeModel = $m | .ccproxy.activeProvider = $p | .ccproxy.activeDisplay = $d' \
      "$bigide_config")"
    echo "$tmp" > "$bigide_config"
  fi

  # Aggiorna config.yaml di ccproxy: cambia il modello "default"
  if [[ -f "$ccproxy_config" ]]; then
    # Determina api_base
    local api_base
    case "$provider" in
      anthropic) api_base="https://api.anthropic.com" ;;
      openai)    api_base="https://api.openai.com" ;;
      google)    api_base="https://generativelanguage.googleapis.com" ;;
      *)         api_base="https://api.anthropic.com" ;;
    esac

    # Rigenera sezione default nel config.yaml via sed
    sed -i '' "s|model: .*/.*|model: ${model}|;s|api_base: https://.*|api_base: ${api_base}|" \
      "$ccproxy_config" 2>/dev/null || true
  fi

  printf '\033[2J\033[H'
  echo
  echo "  ${_C_GREEN}✓${_C_RESET} Modello selezionato: ${_C_CYAN}${display}${_C_RESET}"
  echo "    ${_C_DIM}(${model})${_C_RESET}"
  echo
  echo "  ${_C_DIM}Il modello verra' usato al prossimo avvio di ccproxy.${_C_RESET}"
  echo
  sleep 1.5
}

# ═══════════════════════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════════════════════

_phase1

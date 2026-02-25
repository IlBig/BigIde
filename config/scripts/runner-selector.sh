#!/usr/bin/env bash
# BigIDE — Runner Selector: login provider + selezione modello AI
# Chiamato da tmux popup (es. prefix + m)
# Due fasi: 1) Configura Provider  2) Seleziona Modello
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

BIGIDE_HOME="${BIGIDE_HOME:-$HOME/.bigide}"
CCPROXY_DIR="$HOME/.ccproxy"

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

# ─── Modello attivo ──────────────────────────────────────────────────────────
_active_model_file="$CCPROXY_DIR/active-model"

_get_active_model() {
  if [[ -f "$_active_model_file" ]]; then
    cat "$_active_model_file" 2>/dev/null
  else
    echo ""
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

  local active_model
  active_model="$(_get_active_model)"

  # Costruisci lista modelli: (tipo|display|model_id|provider)
  # Tipi: "header" (non selezionabile) o "model" (selezionabile)
  local items=()

  if [[ "$st_claude" == "connected" ]]; then
    items+=("header|── Anthropic (Claude MAX) ────────────")
    items+=("model|claude-sonnet-4-5-20250929|anthropic/claude-sonnet-4-5-20250929|anthropic")
    items+=("model|claude-opus-4-5-20251101|anthropic/claude-opus-4-5-20251101|anthropic")
    items+=("model|claude-haiku-4-5-20251001|anthropic/claude-haiku-4-5-20251001|anthropic")
  fi

  if [[ "$st_openai" == "connected" ]]; then
    items+=("header|── OpenAI (Codex) ──────────────────────")
    items+=("model|o3|openai/o3|openai")
    items+=("model|o4-mini|openai/o4-mini|openai")
    items+=("model|gpt-4.1|openai/gpt-4.1|openai")
    items+=("model|codex-mini-latest|openai/codex-mini-latest|openai")
  fi

  if [[ "$st_gemini" == "connected" ]]; then
    items+=("header|── Google (Gemini) ─────────────────────")
    items+=("model|gemini-2.5-pro|gemini/gemini-2.5-pro|google")
    items+=("model|gemini-2.5-flash|gemini/gemini-2.5-flash|google")
    items+=("model|gemini-2.0-flash|gemini/gemini-2.0-flash|google")
  fi

  items+=("header|────────────────────────────────────────")
  items+=("model|◂ Torna ai provider|_back|_back")

  # Se nessun provider connesso, solo il pulsante "torna"
  if [[ "$st_claude" != "connected" && "$st_openai" != "connected" && "$st_gemini" != "connected" ]]; then
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
  if [[ -n "$active_model" ]]; then
    for si in "${!selectable[@]}"; do
      local entry="${items[${selectable[$si]}]}"
      local rest="${entry#*|}"
      local tmp="${rest#*|}"
      local mid="${tmp%%|*}"
      if [[ "$mid" == "$active_model" ]]; then
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
        local model_id="${tmp2%%|*}"
        local mark color active_mark=""

        # Segna modello attivo
        if [[ -n "$active_model" && "$model_id" == "$active_model" ]]; then
          active_mark=" ${_C_GREEN}●${_C_RESET}"
        fi

        if (( i == cur_item )); then
          mark="▸ "; color="$_C_CYAN"
        else
          mark="  "; color="$_C_WHITE"
        fi

        local label="${mark}${display}"
        local label_len=${#label}
        # Calcola spazio per il badge attivo (● = 3 bytes ma 1 colonna visiva, + spazio)
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
        local chosen_model="${tmp%%|*}"
        local chosen_provider="${tmp#*|}"

        if [[ "$chosen_model" == "_back" ]]; then
          # Torna a fase 1
          tput cnorm 2>/dev/null || true
          _phase1
          return $?
        fi

        # Applica modello e genera config ccproxy
        _apply_model "$chosen_model" "$chosen_provider" "$chosen_display" \
          "$st_claude" "$st_openai" "$st_gemini"
        tput cnorm 2>/dev/null || true
        exit 0
        ;;
      q) tput cnorm 2>/dev/null || true; exit 0 ;;
    esac
  done
}

# ═══════════════════════════════════════════════════════════════════════════════
# Applica modello selezionato — genera config ccproxy completa
# ═══════════════════════════════════════════════════════════════════════════════

_apply_model() {
  local model="$1" provider="$2" display="$3"
  local st_claude="${4:-disconnected}" st_openai="${5:-disconnected}" st_gemini="${6:-disconnected}"

  mkdir -p "$CCPROXY_DIR"

  # ── 1. Salva modello attivo ──
  echo "$model" > "$_active_model_file"

  # ── 2. Determina api_base per il modello selezionato ──
  # Nota: per gemini/ LiteLLM gestisce l'URL internamente (non serve api_base)
  local api_base=""
  case "$provider" in
    anthropic) api_base="https://api.anthropic.com" ;;
    openai)    api_base="https://api.openai.com" ;;
    google)    api_base="" ;;  # LiteLLM usa il default per gemini/
    *)         api_base="https://api.anthropic.com" ;;
  esac

  # ── 3. Genera ccproxy.yaml (OAuth sources + hooks) ──
  local oat_lines=""
  [[ "$st_claude" == "connected" ]] && oat_lines="${oat_lines}
    anthropic: \"jq -r '.claudeAiOauth.accessToken' ~/.claude/.credentials.json\""
  [[ "$st_openai" == "connected" ]] && oat_lines="${oat_lines}
    openai: \"jq -r '.tokens.access_token' ~/.codex/auth.json\""
  [[ "$st_gemini" == "connected" ]] && oat_lines="${oat_lines}
    google: \"jq -r '.tokens.access_token' ~/.gemini/auth.json\""

  cat > "$CCPROXY_DIR/ccproxy.yaml" << YAML
ccproxy:
  debug: true
  default_model_passthrough: false
  log_file: ${CCPROXY_DIR}/proxy.log
  oat_sources:${oat_lines}
  hooks:
    - ccproxy.hooks.rule_evaluator
    - ccproxy.hooks.model_router
    - ccproxy.hooks.forward_oauth
  rules:
    - name: background
      rule: ccproxy.rules.MatchModelRule
      params:
        - model_name: claude-haiku-4-5-20251001
    - name: think
      rule: ccproxy.rules.ThinkingRule

litellm:
  host: 127.0.0.1
  port: 4000
  num_workers: 4
YAML

  # ── 4. Genera config.yaml (model routing) ──
  # Modello "default" = quello scelto dall'utente
  # Modello "think" = modello forte per ragionamento esteso
  # Modello "background" = modello veloce per task di sfondo

  local think_model think_base background_model background_base
  case "$provider" in
    anthropic)
      think_model="anthropic/claude-opus-4-5-20251101"
      think_base="https://api.anthropic.com"
      background_model="anthropic/claude-haiku-4-5-20251001"
      background_base="https://api.anthropic.com"
      ;;
    openai)
      think_model="openai/o3"
      think_base="https://api.openai.com"
      background_model="openai/o4-mini"
      background_base="https://api.openai.com"
      ;;
    google)
      think_model="gemini/gemini-2.5-pro"
      think_base=""
      background_model="gemini/gemini-2.5-flash"
      background_base=""
      ;;
    *)
      think_model="anthropic/claude-opus-4-5-20251101"
      think_base="https://api.anthropic.com"
      background_model="anthropic/claude-haiku-4-5-20251001"
      background_base="https://api.anthropic.com"
      ;;
  esac

  # model_group_alias: mappa qualsiasi nome modello di Claude Code → "default"
  # Claude Code invia il proprio model ID (es. claude-sonnet-4-6), il proxy lo redirige
  local _CLAUDE_ALIASES=(
    "claude-sonnet-4-5-20250514" "claude-sonnet-4-5-20250929"
    "claude-sonnet-4-6" "claude-sonnet-4-6-20250901"
    "claude-opus-4-5-20250514" "claude-opus-4-5-20251101"
    "claude-opus-4-6" "claude-opus-4-6-20250901"
    "claude-haiku-4-5-20251001"
    "claude-3-5-sonnet-20241022" "claude-3-5-haiku-20241022"
    "claude-sonnet-4-5-latest" "claude-opus-4-5-latest"
  )
  local alias_yaml=""
  for alias in "${_CLAUDE_ALIASES[@]}"; do
    alias_yaml="${alias_yaml}
    \"${alias}\": \"default\""
  done

  # Helper: genera blocco litellm_params (con/senza api_base)
  _litellm_block() {
    local name="$1" m="$2" base="$3"
    echo "  - model_name: $name"
    echo "    litellm_params:"
    echo "      model: $m"
    [[ -n "$base" ]] && echo "      api_base: $base"
  }

  {
    echo "model_list:"
    _litellm_block "default"    "$model"            "$api_base"
    echo
    _litellm_block "think"      "$think_model"      "$think_base"
    echo
    _litellm_block "background" "$background_model"  "$background_base"
    cat << YAML_TAIL

litellm_settings:
  set_verbose: false
  json_logs: true
  log_responses: true
  callbacks:
    - ccproxy.handler

router_settings:
  model_group_alias:${alias_yaml}

general_settings:
  forward_client_headers_to_llm_api: true
YAML_TAIL
  } > "$CCPROXY_DIR/config.yaml"

  # ── 5. Riavvio Claude Code con --resume ──
  _restart_claude_resume

  # ── 6. Feedback visivo ──
  printf '\033[2J\033[H'
  echo
  echo "  ${_C_GREEN}✓${_C_RESET} Modello selezionato: ${_C_CYAN}${display}${_C_RESET}"
  echo "    ${_C_DIM}(${model})${_C_RESET}"
  echo
  echo "  ${_C_DIM}Claude Code si sta riavviando con --resume...${_C_RESET}"
  echo
  sleep 1.2
}

# ═══════════════════════════════════════════════════════════════════════════════
# Riavvia Claude Code nel pane tmux con --resume
# ═══════════════════════════════════════════════════════════════════════════════

_restart_claude_resume() {
  # Riavvia ccproxy daemon con la nuova config
  if command -v ccproxy >/dev/null 2>&1; then
    ccproxy --config-dir "$CCPROXY_DIR" stop 2>/dev/null || true
    # Il proxy verrà riavviato da launch-claude.sh
  fi

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

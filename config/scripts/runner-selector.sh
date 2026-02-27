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

# ─── Gemini API Key ──────────────────────────────────────────────────────────
GEMINI_API_KEY_FILE="$BIGIDE_HOME/gemini-api-key"

_get_gemini_api_key() {
  # Priorità: env var > file
  if [[ -n "${GEMINI_API_KEY:-}" ]]; then echo "$GEMINI_API_KEY"; return; fi
  if [[ -n "${GOOGLE_API_KEY:-}" ]]; then echo "$GOOGLE_API_KEY"; return; fi
  if [[ -f "$GEMINI_API_KEY_FILE" ]]; then cat "$GEMINI_API_KEY_FILE" 2>/dev/null; return; fi
  echo ""
}

# ─── Stato provider ──────────────────────────────────────────────────────────
_check_provider() {
  local script="$BIGIDE_REPO_ROOT/config/scripts/oauth-${1}.mjs"
  [[ -f "$script" ]] && node "$script" ensure 2>/dev/null
}

_provider_status() {
  if [[ "$1" == "gemini" ]]; then
    # Gemini: basta la API key per funzionare
    local key
    key="$(_get_gemini_api_key)"
    if [[ -n "$key" ]]; then
      echo "connected"
    else
      echo "disconnected"
    fi
  else
    if _check_provider "$1"; then
      echo "connected"
    else
      echo "disconnected"
    fi
  fi
}

# ─── Fetch dinamico modelli (come BigBot/src/gateway/server.ts) ───────────────

_fetch_openai_models() {
  # Ritorna lista modelli OpenAI filtrati, uno per riga
  local token
  token="$(jq -r '.tokens.access_token // empty' "$HOME/.codex/auth.json" 2>/dev/null)" || true
  if [[ -z "$token" ]]; then _fallback_openai_models; return; fi

  local response
  response="$(curl -sf --max-time 5 \
    -H "Authorization: Bearer $token" \
    "https://api.openai.com/v1/models" 2>/dev/null)" || { _fallback_openai_models; return; }

  local models
  models="$(echo "$response" | jq -r '
    .data[].id
    | select(test("^(gpt-|o[0-9])"))
    | select(test("(realtime|audio|search|transcribe|tts|whisper|embed|dall-e|image|sora|moderation)") | not)
  ' 2>/dev/null | sort -rV)" || { _fallback_openai_models; return; }

  if [[ -z "$models" ]]; then _fallback_openai_models; return; fi
  echo "$models"
}

_fallback_openai_models() {
  # Allineato a BigBot/openclaw + OpenAI API febbraio 2026
  printf '%s\n' \
    "gpt-5.2" \
    "gpt-5.1" "gpt-5.1-codex" "gpt-5.1-codex-mini" "gpt-5.1-codex-max" \
    "gpt-5.3-codex" \
    "gpt-5-mini" \
    "o3" "o3-pro" "o4-mini" \
    "gpt-4.1" "gpt-4.1-mini" "gpt-4.1-nano" \
    "gpt-4o" "gpt-4o-mini"
}

_fetch_gemini_models() {
  local api_key
  api_key="$(_get_gemini_api_key)"
  if [[ -z "$api_key" ]]; then _fallback_gemini_models; return; fi

  local response
  response="$(curl -sf --max-time 5 \
    "https://generativelanguage.googleapis.com/v1beta/models?pageSize=100&key=${api_key}" 2>/dev/null)" || { _fallback_gemini_models; return; }

  local models
  models="$(echo "$response" | jq -r '
    .models[]
    | select(.supportedGenerationMethods? // [] | index("generateContent"))
    | .name | sub("^models/"; "")
    | select(test("^gemini-"))
  ' 2>/dev/null | sort -rV)" || { _fallback_gemini_models; return; }

  if [[ -z "$models" ]]; then _fallback_gemini_models; return; fi
  echo "$models"
}

_fallback_gemini_models() {
  # Allineato a Google AI docs febbraio 2026
  printf '%s\n' \
    "gemini-3.1-pro-preview" \
    "gemini-3-flash-preview" "gemini-3-pro-preview" \
    "gemini-2.5-pro" "gemini-2.5-flash" "gemini-2.5-flash-lite"
}

# ─── Genera runner config per provider non-Anthropic ─────────────────────────
# Nota: per openai/gemini la traduzione API avviene tramite LiteLLM proxy,
# quindi non serve piu' generare settings.json con ANTHROPIC_BASE_URL.
# I file active-runner e active-model sono gestiti da _apply_selection.
_create_runner_config() {
  # No-op: il proxy LiteLLM gestisce la traduzione API.
  # Mantenuto per compatibilita' con eventuali runner custom.
  :
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
  local sel=3  # default su "Seleziona Modello"
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
    badge_text="$([[ "$status_gemini" == "connected" ]] && echo "✓ API Key" || echo "✗ serve API Key")"
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
        IFS= read -rsn1 -t 1 seq1 </dev/tty || true
        IFS= read -rsn1 -t 1 seq2 </dev/tty || true
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
          2)  # Configura Gemini (API Key)
            printf '\033[2J\033[H'
            tput cnorm 2>/dev/null || true
            echo
            echo "  ${_C_VIOLET}Google Gemini — Configurazione API Key${_C_RESET}"
            echo
            echo "  ${_C_DIM}Per usare Gemini serve una API Key gratuita.${_C_RESET}"
            echo "  ${_C_DIM}Ottienila da: ${_C_CYAN}https://aistudio.google.com/apikey${_C_RESET}"
            echo
            local current_key
            current_key="$(_get_gemini_api_key)"
            if [[ -n "$current_key" ]]; then
              echo "  ${_C_GREEN}✓ API Key configurata${_C_RESET} (${current_key:0:8}...)"
              echo
              echo -n "  Nuova key (Invio per mantenere, 'd' per rimuovere): "
            else
              echo -n "  Incolla la API Key: "
            fi
            local api_input
            IFS= read -r api_input </dev/tty
            api_input="${api_input## }"  # trim leading spaces
            api_input="${api_input%% }"  # trim trailing spaces
            if [[ "$api_input" == "d" || "$api_input" == "D" ]]; then
              rm -f "$GEMINI_API_KEY_FILE"
              echo "  ${_C_RED}API Key rimossa${_C_RESET}"
            elif [[ -n "$api_input" ]]; then
              mkdir -p "$BIGIDE_HOME"
              echo -n "$api_input" > "$GEMINI_API_KEY_FILE"
              chmod 600 "$GEMINI_API_KEY_FILE"
              echo "  ${_C_GREEN}✓ API Key salvata${_C_RESET}"
            fi
            echo; echo "  Premi un tasto per tornare al menu..."
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
# FASE 2 — Seleziona Modello / Runner
# ═══════════════════════════════════════════════════════════════════════════════

_phase2() {
  local st_claude="${1:-disconnected}"
  local st_openai="${2:-disconnected}"
  local st_gemini="${3:-disconnected}"

  local active_key
  active_key="$(_get_active_key)"

  # Costruisci lista: (tipo|display|item_key|action_type)
  #   item_key = "<provider>:<model>" — es. "anthropic:sonnet", "openai:o3"
  #   action_type = "anthropic" | "openai" | "gemini" | "custom"
  local items=()

  # ── Modelli Anthropic (nativi, --model flag) ──
  if [[ "$st_claude" == "connected" ]]; then
    items+=("header|── Anthropic (Claude MAX) ────────────")
    items+=("model|Sonnet 4.6|anthropic:sonnet|anthropic")
    items+=("model|Opus 4.6|anthropic:opus|anthropic")
    items+=("model|Haiku 4.5|anthropic:haiku|anthropic")
    items+=("model|OpusPlan (opus+sonnet)|anthropic:opusplan|anthropic")
  fi

  # ── Modelli OpenAI (fetch dinamico da API, fallback statico) ──
  if [[ "$st_openai" == "connected" ]]; then
    items+=("header|── OpenAI (Codex) ──────────────────────")
    while IFS= read -r m; do
      [[ -n "$m" ]] && items+=("model|${m}|openai:${m}|openai")
    done < <(_fetch_openai_models)
  fi

  # ── Modelli Gemini (fetch dinamico da API, fallback statico) ──
  if [[ "$st_gemini" == "connected" ]]; then
    items+=("header|── Google (Gemini) ─────────────────────")
    while IFS= read -r m; do
      [[ -n "$m" ]] && items+=("model|${m}|gemini:${m}|gemini")
    done < <(_fetch_gemini_models)
  fi

  # ── Runner custom (CLAUDE_CONFIG_DIR) ──
  local has_custom=false
  if [[ -d "$RUNNERS_DIR" ]]; then
    for rdir in "$RUNNERS_DIR"/*/; do
      [[ -f "${rdir}settings.json" ]] || continue
      has_custom=true
      local rname
      rname="$(basename "$rdir")"
      local rmodel
      rmodel="$(jq -r '.env.ANTHROPIC_MODEL // "n/a"' "${rdir}settings.json" 2>/dev/null)" || rmodel="n/a"
      items+=("model|${rname} (${rmodel})|custom:${rname}|custom")
    done
  fi

  if [[ "$has_custom" == true ]]; then
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
  local any_connected=false
  [[ "$st_claude" == "connected" || "$st_openai" == "connected" || "$st_gemini" == "connected" || "$has_custom" == true ]] && any_connected=true
  if [[ "$any_connected" != true ]]; then
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

  # Chrome: top border(1) + vuota(1) + titolo(1) + vuota(1) + vuota(1) + footer(1) + bottom(1) = 7
  local chrome=7
  local n_items=${#items[@]}
  local max_visible=$(( TERM_H - chrome - 2 ))  # -2 margine
  (( max_visible < 5 )) && max_visible=5 || true
  (( max_visible > n_items )) && max_visible=$n_items || true

  local box_h=$(( max_visible + chrome ))
  local top=$(( (TERM_H - box_h) / 2 ))
  (( top < 1 )) && top=1 || true

  local scroll_off=0  # primo item visibile

  # Assicura che l'item selezionato sia visibile
  _scroll_to_sel() {
    local cur_item=${selectable[$sel_idx]}
    # Scorri in basso se l'item è sotto il viewport
    while (( cur_item >= scroll_off + max_visible )); do
      (( scroll_off++ ))
    done
    # Scorri in alto se l'item è sopra il viewport
    while (( cur_item < scroll_off )); do
      (( scroll_off-- ))
    done
  }

  _scroll_to_sel  # posiziona viewport sull'item pre-selezionato

  tput civis 2>/dev/null || true

  _p2_draw() {
    local r=$top c=$col w=$box_w
    local cur_item=${selectable[$sel_idx]}
    local need_scroll=0
    (( n_items > max_visible )) && need_scroll=1 || true

    # ── Scrollbar: calcola posizione thumb ──
    local sb_thumb_start=0 sb_thumb_end=0
    if (( need_scroll )); then
      local sb_size=$(( max_visible * max_visible / n_items ))
      (( sb_size < 1 )) && sb_size=1 || true
      local sb_range=$(( max_visible - sb_size ))
      local scroll_range=$(( n_items - max_visible ))
      if (( scroll_range > 0 )); then
        sb_thumb_start=$(( scroll_off * sb_range / scroll_range ))
      fi
      sb_thumb_end=$(( sb_thumb_start + sb_size ))
    fi

    # ── Top border ──
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

    # ── Items (solo viewport) ──
    local opad=4
    local vi=0  # indice viewport (0..max_visible-1)
    local i=$(( scroll_off ))
    while (( vi < max_visible && i < n_items )); do
      local entry="${items[$i]}"
      local type="${entry%%|*}"
      local rest="${entry#*|}"

      # Scrollbar: bordo destro
      local rborder="│"
      if (( need_scroll )); then
        if (( vi >= sb_thumb_start && vi < sb_thumb_end )); then
          rborder="┃"
        fi
      fi

      _goto "$r" "$c"

      if [[ "$type" == "header" ]]; then
        local htext="$rest"
        printf '%s│%*s%s%s%*s%s%s%s' \
          "$_C_FRAME" "$opad" "" "$_C_DIM" "$htext" $(( w - opad - ${#htext} )) "" "$_C_FRAME" "$rborder" "$_C_RESET"
      else
        local display="${rest%%|*}"
        local tmp2="${rest#*|}"
        local item_key="${tmp2%%|*}"
        local mark color active_mark=""

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
          active_visual=2
        fi
        local pad=$(( w - opad - label_len - active_visual ))
        (( pad < 0 )) && pad=0 || true

        printf '%s│%*s%s%s%*s%s%s%s%s' \
          "$_C_FRAME" "$opad" "" "$color" "$label" "$pad" "" "$active_mark" "$_C_FRAME" "$rborder" "$_C_RESET"
      fi
      (( r++ ))
      (( vi++ ))
      (( i++ ))
    done

    # Vuota
    _goto "$r" "$c"; printf '%s│%*s│%s' "$_C_FRAME" "$w" "" "$_C_RESET"; (( r++ ))

    # Footer
    local hint="↑↓ naviga  Enter seleziona  Esc esci"
    if (( need_scroll )); then
      hint="↑↓ scorri  Enter seleziona  Esc esci"
    fi
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

  _p2_nav() {
    _scroll_to_sel
    _p2_draw
  }

  printf '\033[2J\033[H'
  _p2_draw

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
            A) (( sel_idx = (sel_idx - 1 + n_sel) % n_sel )); _p2_nav ;;
            B) (( sel_idx = (sel_idx + 1) % n_sel )); _p2_nav ;;
          esac
        else
          tput cnorm 2>/dev/null || true; exit 0
        fi
        ;;
      k) (( sel_idx = (sel_idx - 1 + n_sel) % n_sel )); _p2_nav ;;
      j) (( sel_idx = (sel_idx + 1) % n_sel )); _p2_nav ;;
      $'\t') (( sel_idx = (sel_idx + 1) % n_sel )); _p2_nav ;;
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
  elif [[ "$action_type" == "openai" ]]; then
    # item_key = "openai:<model>" → es. "openai:o3"
    local model="${item_key#openai:}"
    echo "openai" > "$BIGIDE_HOME/active-runner"
    echo "$model" > "$BIGIDE_HOME/active-model"
    # Genera runner config con token OAuth fresco
    _create_runner_config "openai" "$model"
  elif [[ "$action_type" == "gemini" ]]; then
    # item_key = "gemini:<model>" → es. "gemini:gemini-2.5-pro"
    local model="${item_key#gemini:}"
    echo "gemini" > "$BIGIDE_HOME/active-runner"
    echo "$model" > "$BIGIDE_HOME/active-model"
    _create_runner_config "gemini" "$model"
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

  # Recupera project path salvato da create_layout
  local project_path
  project_path="$(cat "$BIGIDE_HOME/active-project-path" 2>/dev/null)" || project_path=""
  project_path="${project_path/#\~/$HOME}"

  # respawn-pane -k: uccide il processo corrente e avvia una nuova shell
  tmux respawn-pane -k -t "$claude_pane" 2>/dev/null || true
  sleep 0.4

  # Rilancia Claude con --resume nella nuova shell, nella cartella del progetto
  if [[ -n "$project_path" ]]; then
    tmux send-keys -t "$claude_pane" "cd '${project_path}' && clear; \$HOME/.bigide/scripts/launch-claude.sh --resume" C-m
  else
    tmux send-keys -t "$claude_pane" 'clear; $HOME/.bigide/scripts/launch-claude.sh --resume' C-m
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════════════════════

_phase1

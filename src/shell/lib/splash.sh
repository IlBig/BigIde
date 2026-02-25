#!/usr/bin/env bash
set -euo pipefail

# ── Splash Screen Retro 80s ── Tokyo Night Theme ──────────────────────

# Colori Tokyo Night (truecolor)
_SP_DIM=$'\033[38;2;59;66;97m'        # #3b4261 — cornice + barra vuota
_SP_CYAN=$'\033[38;2;125;207;255m'    # #7dcfff — barra piena
_SP_WHITE=$'\033[38;2;192;202;245m'   # #c0caf5 — percentuale
_SP_ORANGE=$'\033[38;2;255;158;100m'  # #ff9e64 — testo step
_SP_VIOLET=$'\033[38;2;187;154;247m'  # #bb9af7 — subtitle
_SP_COMMENT=$'\033[38;2;86;95;137m'    # #565f89 — testo dim/non selezionato
_SP_RESET=$'\033[0m'

# Colori lettere logo — rainbow 80s (B-I-G-I-D-E)
_SP_L1=$'\033[38;2;247;118;142m'      # #f7768e pink
_SP_L2=$'\033[38;2;255;158;100m'      # #ff9e64 orange
_SP_L3=$'\033[38;2;224;175;104m'      # #e0af68 yellow
_SP_L4=$'\033[38;2;158;206;106m'      # #9ece6a green
_SP_L5=$'\033[38;2;122;162;247m'      # #7aa2f7 blue
_SP_L6=$'\033[38;2;187;154;247m'      # #bb9af7 violet

_SP_BAR_LEN=30
_SP_BOX_W=70     # larghezza interna del box (tra │ e │)
_SP_TERM_W=80
_SP_TERM_H=24

# Ripristina cursore su interruzione
trap 'tput cnorm 2>/dev/null || true' EXIT

# ── Helpers ────────────────────────────────────────────────────────────

_sp_goto() { printf '\033[%d;%dH' "$1" "$2"; }

# Rileva dimensioni reali del terminale (stty > tput > env > default)
_sp_detect_size() {
  local size
  if [[ -t 0 ]] && size=$(stty size 2>/dev/null) && [[ -n "$size" ]]; then
    _SP_TERM_H="${size%% *}"
    _SP_TERM_W="${size##* }"
  elif [[ -t 1 ]] && size=$(stty size </dev/tty 2>/dev/null) && [[ -n "$size" ]]; then
    _SP_TERM_H="${size%% *}"
    _SP_TERM_W="${size##* }"
  else
    _SP_TERM_W="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"
    _SP_TERM_H="${LINES:-$(tput lines 2>/dev/null || echo 24)}"
  fi
}

# Disegna riga vuota della cornice: │<spaces>│
_sp_frame_row() {
  _sp_goto "$1" "$2"
  printf '%s│%*s│%s' "$_SP_DIM" "$_SP_BOX_W" "" "$_SP_RESET"
}

# Stampa una riga del logo con 6 segmenti colorati (B I G I D E)
_sp_logo_row() {
  local row=$1 col=$2; shift 2
  _sp_goto "$row" "$col"
  printf '%s%s'    "$_SP_L1" "$1"
  printf '   %s%s' "$_SP_L2" "$2"
  printf '   %s%s' "$_SP_L3" "$3"
  printf '   %s%s' "$_SP_L4" "$4"
  printf '   %s%s' "$_SP_L5" "$5"
  printf '   %s%s' "$_SP_L6" "$6"
  printf '%s' "$_SP_RESET"
}

# ── init_splash ────────────────────────────────────────────────────────

init_splash() {
  tput civis 2>/dev/null || true
  printf '\033[2J\033[H'

  # Rileva dimensioni reali del terminale
  _sp_detect_size

  local box_total=$(( _SP_BOX_W + 2 ))
  local col=$(( (_SP_TERM_W - box_total) / 2 ))
  (( col < 1 )) && col=1 || true

  # Centra verticalmente (box = 17 righe)
  local box_h=17
  _SP_TOP_ROW=$(( (_SP_TERM_H - box_h) / 2 ))
  (( _SP_TOP_ROW < 1 )) && _SP_TOP_ROW=1 || true

  local r=$_SP_TOP_ROW

  # ── Cornice top (generata dinamicamente) ──
  _sp_goto "$r" "$col"
  printf '%s┌' "$_SP_DIM"
  printf '─%.0s' $(seq 1 $_SP_BOX_W)
  printf '┐%s' "$_SP_RESET"
  (( r++ ))

  # ── 2 righe vuote ──
  _sp_frame_row "$r" "$col"; (( r++ ))
  _sp_frame_row "$r" "$col"; (( r++ ))

  # ── ASCII Art Logo (6 righe, ogni lettera di colore diverso) ──
  # Logo width: B(8)+3+I(3)+3+G(9)+3+I(3)+3+D(8)+3+E(8) = 54
  local logo_w=54
  local logo_pad=$(( (_SP_BOX_W - logo_w) / 2 ))
  local lcol=$(( col + 1 + logo_pad ))

  # Riga 0
  _sp_frame_row "$r" "$col"
  _sp_logo_row "$r" "$lcol" \
    "██████╗ " "██╗" " ██████╗ " "██╗" "██████╗ " "███████╗"
  (( r++ ))

  # Riga 1
  _sp_frame_row "$r" "$col"
  _sp_logo_row "$r" "$lcol" \
    "██╔══██╗" "██║" "██╔════╝ " "██║" "██╔══██╗" "██╔════╝"
  (( r++ ))

  # Riga 2
  _sp_frame_row "$r" "$col"
  _sp_logo_row "$r" "$lcol" \
    "██████╔╝" "██║" "██║  ███╗" "██║" "██║  ██║" "█████╗  "
  (( r++ ))

  # Riga 3
  _sp_frame_row "$r" "$col"
  _sp_logo_row "$r" "$lcol" \
    "██╔══██╗" "██║" "██║   ██║" "██║" "██║  ██║" "██╔══╝  "
  (( r++ ))

  # Riga 4
  _sp_frame_row "$r" "$col"
  _sp_logo_row "$r" "$lcol" \
    "██████╔╝" "██║" "╚██████╔╝" "██║" "██████╔╝" "███████╗"
  (( r++ ))

  # Riga 5
  _sp_frame_row "$r" "$col"
  _sp_logo_row "$r" "$lcol" \
    "╚═════╝ " "╚═╝" " ╚═════╝ " "╚═╝" "╚═════╝ " "╚══════╝"
  (( r++ ))

  # ── Riga vuota ──
  _sp_frame_row "$r" "$col"; (( r++ ))

  # ── Subtitle ──
  _sp_frame_row "$r" "$col"
  local subtitle='⚡ Terminal-First IDE ⚡'
  local sub_col=$(( col + 1 + (_SP_BOX_W - ${#subtitle}) / 2 ))
  _sp_goto "$r" "$sub_col"
  printf '%s%s%s' "$_SP_VIOLET" "$subtitle" "$_SP_RESET"
  (( r++ ))

  # ── Riga vuota ──
  _sp_frame_row "$r" "$col"; (( r++ ))

  # ── Riga barra (segnaposto) ──
  export _SP_BAR_ROW=$r
  _sp_frame_row "$r" "$col"
  (( r++ ))

  # ── Riga percentuale (segnaposto) ──
  export _SP_PCT_ROW=$r
  _sp_frame_row "$r" "$col"
  (( r++ ))

  # ── Riga step (segnaposto) ──
  export _SP_STEP_ROW=$r
  _sp_frame_row "$r" "$col"
  local _init_step="▸ Avvio..."
  local _init_pad=$(( (_SP_BOX_W - ${#_init_step}) / 2 ))
  _sp_goto "$r" "$(( col + 1 + _init_pad ))"
  printf '%s%s%s' "$_SP_ORANGE" "$_init_step" "$_SP_RESET"
  (( r++ ))

  # ── Riga vuota ──
  _sp_frame_row "$r" "$col"; (( r++ ))

  # ── Cornice bottom (generata dinamicamente) ──
  _sp_goto "$r" "$col"
  printf '%s└' "$_SP_DIM"
  printf '─%.0s' $(seq 1 $_SP_BOX_W)
  printf '┘%s' "$_SP_RESET"

  export _SP_BOX_COL=$col
}

# ── show_splash ────────────────────────────────────────────────────────

show_splash() {
  local step_text="$1"
  local pct="$2"
  local col="${_SP_BOX_COL:-1}"

  # Calcola segmenti pieni/vuoti
  local filled=$(( pct * _SP_BAR_LEN / 100 ))
  (( filled > _SP_BAR_LEN )) && filled=$_SP_BAR_LEN || true
  local empty=$(( _SP_BAR_LEN - filled ))

  local pct_str
  pct_str=$(printf '%d%%' "$pct")

  # Centra la barra (solo blocchi, senza percentuale)
  local bar_pad=$(( (_SP_BOX_W - _SP_BAR_LEN) / 2 ))

  # ── Aggiorna riga barra ──
  _sp_frame_row "${_SP_BAR_ROW:-12}" "$col"
  _sp_goto "${_SP_BAR_ROW:-12}" "$(( col + 1 + bar_pad ))"
  if (( filled > 0 )); then
    printf '%s' "$_SP_CYAN"
    printf '█%.0s' $(seq 1 "$filled")
  fi
  if (( empty > 0 )); then
    printf '%s' "$_SP_DIM"
    printf '░%.0s' $(seq 1 "$empty")
  fi
  printf '%s' "$_SP_RESET"

  # ── Aggiorna riga percentuale ──
  _sp_frame_row "${_SP_PCT_ROW:-13}" "$col"
  local pct_pad=$(( (_SP_BOX_W - ${#pct_str}) / 2 ))
  _sp_goto "${_SP_PCT_ROW:-13}" "$(( col + 1 + pct_pad ))"
  printf '%s%s%s' "$_SP_WHITE" "$pct_str" "$_SP_RESET"

  # ── Aggiorna riga step ──
  _sp_frame_row "${_SP_STEP_ROW:-14}" "$col"
  local step_display="▸ ${step_text}"
  local max_len=$(( _SP_BOX_W - 2 ))
  if (( ${#step_display} > max_len )); then
    step_display="${step_display:0:$max_len}"
  fi
  local step_pad=$(( (_SP_BOX_W - ${#step_display}) / 2 ))
  _sp_goto "${_SP_STEP_ROW:-13}" "$(( col + 1 + step_pad ))"
  printf '%s%s%s' "$_SP_ORANGE" "$step_display" "$_SP_RESET"
}

# ── show_session_dialog ────────────────────────────────────────────────
# Mostra popup centrato "sessione esistente" stile Tokyo Night.
# Argomento: nome sessione.  Return: 0 = Nuova, 1 = Continua.

show_session_dialog() {
  local session_name="$1"
  local sel=0  # 0 = Nuova (default), 1 = Continua

  _sp_detect_size

  local box_inner=46
  local box_total=$(( box_inner + 2 ))
  local col=$(( (_SP_TERM_W - box_total) / 2 ))
  (( col < 1 )) && col=1 || true
  local box_h=8
  local top=$(( (_SP_TERM_H - box_h) / 2 ))
  (( top < 1 )) && top=1 || true

  tput civis 2>/dev/null || true

  # ── Funzione ridisegno ──
  _ssd_draw() {
    local r=$top c=$col w=$box_inner

    # Cornice top
    _sp_goto "$r" "$c"
    printf '%s┌' "$_SP_DIM"
    printf '─%.0s' $(seq 1 "$w")
    printf '┐%s' "$_SP_RESET"
    (( r++ ))

    # Riga vuota
    _sp_goto "$r" "$c"
    printf '%s│%*s│%s' "$_SP_DIM" "$w" "" "$_SP_RESET"
    (( r++ ))

    # Riga 1 messaggio: "La sessione 'xxx'"
    local msg1="La sessione '${session_name}'"
    local pad1=$(( (w - ${#msg1}) / 2 ))
    _sp_goto "$r" "$c"
    printf '%s│%*s%s%s%*s│%s' \
      "$_SP_DIM" "$pad1" "" \
      "$_SP_WHITE" "$msg1" \
      $(( w - pad1 - ${#msg1} )) "" "$_SP_RESET"
    (( r++ ))

    # Riga 2 messaggio: "esiste già. Cosa vuoi fare?"
    local msg2="esiste già. Cosa vuoi fare?"
    local pad2=$(( (w - ${#msg2}) / 2 ))
    _sp_goto "$r" "$c"
    printf '%s│%*s%s%s%*s│%s' \
      "$_SP_DIM" "$pad2" "" \
      "$_SP_WHITE" "$msg2" \
      $(( w - pad2 - ${#msg2} )) "" "$_SP_RESET"
    (( r++ ))

    # Riga vuota
    _sp_goto "$r" "$c"
    printf '%s│%*s│%s' "$_SP_DIM" "$w" "" "$_SP_RESET"
    (( r++ ))

    # Opzione 1: Nuova sessione
    local lbl1_marker lbl1_color
    if (( sel == 0 )); then
      lbl1_marker="▸  Nuova sessione"
      lbl1_color="$_SP_CYAN"
    else
      lbl1_marker="   Nuova sessione"
      lbl1_color="$_SP_COMMENT"
    fi
    local opad=8
    local rpad=$(( w - opad - ${#lbl1_marker} ))
    _sp_goto "$r" "$c"
    printf '%s│%*s%s%s%*s%s│%s' \
      "$_SP_DIM" "$opad" "" \
      "$lbl1_color" "$lbl1_marker" \
      "$rpad" "" "$_SP_DIM" "$_SP_RESET"
    (( r++ ))

    # Opzione 2: Continua sessione
    local lbl2_marker lbl2_color
    if (( sel == 1 )); then
      lbl2_marker="▸  Continua sessione"
      lbl2_color="$_SP_CYAN"
    else
      lbl2_marker="   Continua sessione"
      lbl2_color="$_SP_COMMENT"
    fi
    local rpad2=$(( w - opad - ${#lbl2_marker} ))
    _sp_goto "$r" "$c"
    printf '%s│%*s%s%s%*s%s│%s' \
      "$_SP_DIM" "$opad" "" \
      "$lbl2_color" "$lbl2_marker" \
      "$rpad2" "" "$_SP_DIM" "$_SP_RESET"
    (( r++ ))

    # Riga vuota
    _sp_goto "$r" "$c"
    printf '%s│%*s│%s' "$_SP_DIM" "$w" "" "$_SP_RESET"
    (( r++ ))

    # Cornice bottom
    _sp_goto "$r" "$c"
    printf '%s└' "$_SP_DIM"
    printf '─%.0s' $(seq 1 "$w")
    printf '┘%s' "$_SP_RESET"
  }

  # ── Disegno iniziale ──
  printf '\033[2J\033[H'
  _ssd_draw

  # ── Loop input ──
  local key
  while true; do
    IFS= read -rsn1 key </dev/tty
    case "$key" in
      $'\033')  # Sequenza escape (frecce) oppure Esc puro
        local seq1 seq2
        IFS= read -rsn1 -t 0.05 seq1 </dev/tty || true
        IFS= read -rsn1 -t 0.05 seq2 </dev/tty || true
        if [[ "$seq1" == "[" ]]; then
          case "$seq2" in
            A) (( sel = sel == 0 ? 1 : 0 )); _ssd_draw ;;  # ↑
            B) (( sel = sel == 0 ? 1 : 0 )); _ssd_draw ;;  # ↓
          esac
        else
          # Esc puro → annulla
          tput cnorm 2>/dev/null || true
          exit 0
        fi
        ;;
      j|k)  # vim navigation
        (( sel = sel == 0 ? 1 : 0 ))
        _ssd_draw
        ;;
      $'\t')  # Tab
        (( sel = sel == 0 ? 1 : 0 ))
        _ssd_draw
        ;;
      "")  # Enter
        tput cnorm 2>/dev/null || true
        return "$sel"
        ;;
      q)  # Quit
        tput cnorm 2>/dev/null || true
        exit 0
        ;;
    esac
  done
}

# ── end_splash ─────────────────────────────────────────────────────────

end_splash() {
  show_splash "Pronto!" 100
  sleep 0.5
  printf '\033[2J\033[H'
  tput cnorm 2>/dev/null || true
}

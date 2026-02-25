#!/usr/bin/env bash
# BigIDE — Preview immagini/video/documenti
# Rendering: chafa --symbols all (ottanti+braille, miglior qualità block chars)
# Nessun testo UI: premi qualsiasi tasto per chiudere

# Assicura che Homebrew sia nel PATH (il popup tmux non carica il profilo shell)
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

FILEPATH="$1"
ext="$(echo "${FILEPATH##*.}" | tr '[:upper:]' '[:lower:]')"

PREV_DIR="$HOME/.bigide/previews"
mkdir -p "$PREV_DIR"

# Pulizia terminale all'uscita: ripristina cursore sempre
trap 'printf "\033[?25h\033[0m"' EXIT

_show() {
  local file="$1"
  local W H
  W=$(tput cols  2>/dev/null || echo 80)
  H=$(tput lines 2>/dev/null || echo 24)

  # chafa: migliore qualità block chars disponibile in tmux
  # --symbols all = ottanti+braille+quarter = ~4x risoluzione vs half-blocks
  chafa \
    --format=symbols \
    --symbols all \
    --colors 256 \
    --font-ratio 1/2 \
    --align mid,mid \
    --size "${W}x${H}" \
    "$file" 2>/dev/null \
    || printf "\033[38;2;65;72;104m  Anteprima non disponibile\033[0m\n"

  read -rsn1
}

_show_doc() {
  qlmanage -t -s 2400 -o "$PREV_DIR" "$FILEPATH" >/dev/null 2>&1
  local thumb="$PREV_DIR/$(basename "$FILEPATH").png"
  if [[ -f "$thumb" ]]; then
    _show "$thumb"
  else
    printf "\033[38;2;65;72;104m  %s\033[0m\n" "$(file --brief "$FILEPATH" 2>/dev/null)"
    read -rsn1
  fi
}

case "$ext" in
  jpg|jpeg|png|gif|webp|bmp|tiff|tif|ico|heic|heif|svg|avif|jxl|qoi)
    _show "$FILEPATH" ;;
  mp4|mov|avi|mkv|m4v|webm|flv|wmv|3gp|ts|mts|m2ts)
    _show "$FILEPATH" ;;
  pdf|docx|xlsx|pptx|doc|xls|ppt|pages|numbers|key|odp|ods|odt)
    _show_doc ;;
  *)
    W=$(tput cols 2>/dev/null || echo 80)
    H=$(tput lines 2>/dev/null || echo 24)
    chafa --format=symbols --symbols all --colors 256 --font-ratio 1/2 --align mid,mid --size "${W}x${H}" "$FILEPATH" 2>/dev/null \
      && read -rsn1 \
      || { printf "\033[38;2;65;72;104m  %s\033[0m\n" \
           "$(file --brief "$FILEPATH" 2>/dev/null)"; read -rsn1; } ;;
esac

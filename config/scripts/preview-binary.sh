#!/usr/bin/env bash
# BigIDE — Preview file non-testuale in tmux popup centrato
# Usa timg per immagini/video; qlmanage thumbnail per PDF/Office
# q / Esc per chiudere

FILEPATH="$1"

tmux display-popup \
  -E \
  -w "82%" \
  -h "82%" \
  -x "C" \
  -y "C" \
  "bash $HOME/.bigide/scripts/preview-binary-inner.sh $(printf '%q' "$FILEPATH")"

#!/usr/bin/env bash
set -euo pipefail

# Script per la dittatura vocale BigIDE (Whisper.cpp)
# Requisiti: ffmpeg, whisper-cpp

VOICE_DIR="$HOME/.bigide/voice"
mkdir -p "$VOICE_DIR"

AUDIO_FILE="$VOICE_DIR/capture.wav"
TRANSCRIPT_FILE="$VOICE_DIR/capture.txt"
MODEL_PATH="/usr/local/share/whisper-cpp/models/ggml-base.en.bin"

# 1. Registra audio (5 secondi di default o stop con C-c)
echo "Recording... (Press Ctrl-c to stop early)"
ffmpeg -y -f avfoundation -i ":0" -t 5 "$AUDIO_FILE" > /dev/null 2>&1 || true

# 2. Trascrivi
if [[ -f "$AUDIO_FILE" ]]; then
  echo "Transcribing..."
  whisper-cpp -m "$MODEL_PATH" -f "$AUDIO_FILE" -otxt "$TRANSCRIPT_FILE" > /dev/null 2>&1
  
  if [[ -f "$TRANSCRIPT_FILE" ]]; then
    TEXT=$(cat "$TRANSCRIPT_FILE" | tr -d '
' | sed 's/\[.*\]//g')
    echo "Result: $TEXT"
    # Invia al pannello tmux attivo
    tmux send-keys "$TEXT"
  fi
fi

rm -f "$AUDIO_FILE" "$TRANSCRIPT_FILE"

#!/usr/bin/env bash
# Logga un keybinding tmux nel file di log BigIDE.
# Chiamato da tmux.conf con: run-shell -b "bash $HOME/.bigide/scripts/log-key.sh 'key → action'"
printf '%s [KEY] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$HOME/.bigide/logs/bigide.log" 2>/dev/null || true

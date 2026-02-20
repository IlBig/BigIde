#!/usr/bin/env bash

# Placeholder per claude-monitor
# Mostra risorse e stato tmux

while true; do
  clear
  echo "=== BigIDE System Monitor ==="
  echo "Date: $(date)"
  echo
  echo "--- System Resources ---"
  top -l 1 -n 0 -s 0 | grep -E "CPU usage|PhysMem"
  echo
  echo "--- Active Panes ---"
  tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} (#{pane_width}x#{pane_height}) - #{pane_current_command}" | head -n 10
  
  sleep 5
done

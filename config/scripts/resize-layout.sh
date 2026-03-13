#!/usr/bin/env bash
# BigIDE — Resize dinamico layout pane
# Chiamato dal hook client-resized di tmux
# Layout: yazi | claude (sopra) / terminal+logs (sotto) | gitbar (1 riga)
# Terminal e logs: affiancati orizzontalmente se ≥140 col, impilati verticalmente altrimenti
# Yazi: 40 col se wide (≥160), proporzionale se narrow
set -euo pipefail

WIN_ID="${1:-}"
[[ -z "$WIN_ID" ]] && exit 0

# ── Trova i pane per tipo (compatibile bash 3.2) ────────────────────────────
P_YAZI="" P_CLAUDE="" P_TERM="" P_LOGS="" P_GITBAR=""
while IFS=' ' read -r pid ptype; do
  case "$ptype" in
    yazi)     P_YAZI="$pid" ;;
    claude)   P_CLAUDE="$pid" ;;
    terminal) P_TERM="$pid" ;;
    logs)     P_LOGS="$pid" ;;
    gitbar)   P_GITBAR="$pid" ;;
  esac
done < <(tmux list-panes -t "$WIN_ID" -F '#{pane_id} #{@bigide_pane_type}' 2>/dev/null)

[[ -z "$P_YAZI" || -z "$P_TERM" || -z "$P_LOGS" ]] && exit 0

# ── Dimensioni finestra ─────────────────────────────────────────────────────
TW="$(tmux display-message -p -t "$WIN_ID" '#{window_width}' 2>/dev/null)" || exit 0
TH="$(tmux display-message -p -t "$WIN_ID" '#{window_height}' 2>/dev/null)" || exit 0

# ── Gitbar: sempre 1 riga ───────────────────────────────────────────────────
[[ -n "$P_GITBAR" ]] && tmux resize-pane -t "$P_GITBAR" -y 1 2>/dev/null || true

# ── Yazi: 40 col se wide, proporzionale se narrow ───────────────────────────
if (( TW >= 160 )); then
  tmux resize-pane -t "$P_YAZI" -x 40 2>/dev/null || true
else
  YAZI_W=$(( TW * 15 / 100 ))
  (( YAZI_W < 24 )) && YAZI_W=24
  (( YAZI_W > 40 )) && YAZI_W=40
  tmux resize-pane -t "$P_YAZI" -x "$YAZI_W" 2>/dev/null || true
fi

# ── Terminal e logs: layout responsive ──────────────────────────────────────
# ≥140 col → affiancati orizzontalmente | <140 col → impilati verticalmente
TERM_LEFT="$(tmux display-message -p -t "$P_TERM" '#{pane_left}' 2>/dev/null)" || TERM_LEFT=0
LOGS_LEFT="$(tmux display-message -p -t "$P_LOGS" '#{pane_left}' 2>/dev/null)" || LOGS_LEFT=0
CURRENTLY_HORIZONTAL=$( [[ "$TERM_LEFT" != "$LOGS_LEFT" ]] && echo 1 || echo 0 )

if (( TW >= 140 )); then
  # Schermo largo → affiancati orizzontalmente
  if (( ! CURRENTLY_HORIZONTAL )); then
    tmux join-pane -h -l 50% -s "$P_LOGS" -t "$P_TERM" 2>/dev/null || true
  else
    # Già orizzontali → forza proporzioni 50/50
    tmux resize-pane -t "$P_LOGS" -x 50% 2>/dev/null || true
  fi
else
  # Schermo stretto → impilati verticalmente
  if (( CURRENTLY_HORIZONTAL )); then
    TERM_H="$(tmux display-message -p -t "$P_TERM" '#{pane_height}' 2>/dev/null)" || TERM_H=10
    LOGS_H=$(( TERM_H / 2 ))
    (( LOGS_H < 3 )) && LOGS_H=3
    tmux join-pane -v -l "$LOGS_H" -s "$P_LOGS" -t "$P_TERM" 2>/dev/null || true
  else
    # Già verticali → forza proporzioni 50/50
    tmux resize-pane -t "$P_LOGS" -y 50% 2>/dev/null || true
  fi
fi

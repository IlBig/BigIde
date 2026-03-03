#!/usr/bin/env bash
# BigIDE — Ricerca file fuzzy con fzf
# Seleziona un file → lo apre nella preview di neo-tree
# Chiamato da tmux popup (prefix + Spazio)
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

_L() { printf '%s [EVENT] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$HOME/.bigide/logs/bigide.log" 2>/dev/null || true; }

# Assicura cwd = root progetto (il popup potrebbe non ereditarlo)
# Per-window: prova @bigide_project_path dal window corrente
_PROJECT=""
if [[ -n "${BIGIDE_WINDOW:-}" ]]; then
  _PROJECT="$(tmux show-option -wqv -t "$BIGIDE_WINDOW" @bigide_project_path 2>/dev/null)" || true
fi
# Fallback: session_path
if [[ -z "$_PROJECT" || "$_PROJECT" == "$HOME" ]]; then
  _PROJECT="$(tmux display-message -p '#{session_path}' 2>/dev/null)" || true
  _PROJECT="${_PROJECT/#\~/$HOME}"
fi
# Fallback: file globale
if [[ -z "$_PROJECT" || "$_PROJECT" == "$HOME" ]]; then
  _PROJECT="$(cat "$HOME/.bigide/active-project-path" 2>/dev/null)" || true
fi
[[ -n "$_PROJECT" && -d "$_PROJECT" ]] && cd "$_PROJECT" 2>/dev/null || true

_L "file-search: opened in $(pwd)"

RESULT_FILE="/tmp/bigide-fzf-result"
rm -f "$RESULT_FILE"

selected=$(find . \
  -not -path '*/.git/*' \
  -not -path '*/node_modules/*' \
  -not -path '*/__pycache__/*' \
  -not -path '*/.next/*' \
  -not -path '*/.nuxt/*' \
  -not -path '*/build/*' \
  -not -path '*/dist/*' \
  -not -path '*/.cache/*' \
  -not -path '*/.tmp/*' \
  -not -path '*/vendor/*' \
  -not -path '*/Pods/*' \
  -not -path '*/.build/*' \
  -not -path '*/target/*' \
  -not -name '.DS_Store' \
  -type f \
  2>/dev/null | sed 's|^\./||' | sort | \
  fzf \
    --height=100% \
    --layout=reverse \
    --border=rounded \
    --prompt="  " \
    --pointer="▶" \
    --marker="●" \
    --header="Cerca file — Esc chiudi" \
    --preview='cat -n {}' \
    --preview-window='right:50%:border-left' \
    --color='bg+:#2e3c64,fg+:#c0caf5,hl:#ff9e64,hl+:#ff9e64,border:#3b4261,header:#565f89,prompt:#7aa2f7,pointer:#7aa2f7' \
) || true

if [[ -n "$selected" ]]; then
  _L "file-search: selected → $selected"
  echo "$(pwd)/$selected" > "$RESULT_FILE"
  # Notifica neovim (yazi pane) di aprire il file selezionato
  local _yazi_pane=""
  if [[ -n "${BIGIDE_WINDOW:-}" ]]; then
    _yazi_pane=$(tmux list-panes -t "$BIGIDE_WINDOW" -F '#{pane_id} #{@bigide_pane_type}' 2>/dev/null \
      | awk '$2=="yazi"{print $1;exit}')
  fi
  [[ -z "$_yazi_pane" ]] && _yazi_pane=":.0"
  tmux send-keys -t "$_yazi_pane" Escape
  tmux send-keys -t "$_yazi_pane" ":lua BigideOpenSearch()" Enter
fi

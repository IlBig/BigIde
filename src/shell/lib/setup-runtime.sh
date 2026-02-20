#!/usr/bin/env bash
set -euo pipefail

init_runtime() {
  mkdir -p "$BIGIDE_HOME"/{tmux,yazi,nvim,mcp,layouts,logs,scripts,tools}

  [[ -f "$BIGIDE_HOME/config.json" ]] || cp "$BIGIDE_REPO_ROOT/config/default-config.json" "$BIGIDE_HOME/config.json"
  [[ -f "$BIGIDE_HOME/layouts/default.json" ]] || cp "$BIGIDE_REPO_ROOT/config/layouts/default.json" "$BIGIDE_HOME/layouts/default.json"
  [[ -f "$BIGIDE_HOME/tmux/tmux.conf" ]] || cp "$BIGIDE_REPO_ROOT/config/tmux.conf" "$BIGIDE_HOME/tmux/tmux.conf"
  [[ -f "$BIGIDE_HOME/gitmux.conf" ]] || cp "$BIGIDE_REPO_ROOT/config/gitmux.conf" "$BIGIDE_HOME/gitmux.conf"

  mkdir -p "$BIGIDE_HOME/yazi"
  [[ -f "$BIGIDE_HOME/yazi/yazi.toml" ]] || cp "$BIGIDE_REPO_ROOT/config/yazi/yazi.toml" "$BIGIDE_HOME/yazi/yazi.toml"

  if [[ ! -f "$BIGIDE_HOME/scripts/launch-claude.sh" ]]; then
    sed "s#__BIGIDE_REPO_ROOT__#$BIGIDE_REPO_ROOT#g" "$BIGIDE_REPO_ROOT/config/scripts/launch-claude.sh" > "$BIGIDE_HOME/scripts/launch-claude.sh"
    chmod +x "$BIGIDE_HOME/scripts/launch-claude.sh"
  fi
}

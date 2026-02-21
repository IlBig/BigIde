#!/usr/bin/env bash
set -euo pipefail

init_runtime() {
  mkdir -p "$BIGIDE_HOME"/{tmux,yazi,nvim,mcp,layouts,logs,scripts,tools}

  # Configurazione utente (non sovrascrivere se esiste)
  [[ -f "$BIGIDE_HOME/config.json" ]] || cp "$BIGIDE_REPO_ROOT/config/default-config.json" "$BIGIDE_HOME/config.json"

  # Layouts (sovrascrivi per aggiornamenti)
  cp -r "$BIGIDE_REPO_ROOT/config/layouts/" "$BIGIDE_HOME/layouts/"

  # Configurazione tmux (sovrascrivi per aggiornamenti)
  cp "$BIGIDE_REPO_ROOT/config/tmux.conf" "$BIGIDE_HOME/tmux/tmux.conf"
  cp "$BIGIDE_REPO_ROOT/config/gitmux.conf" "$BIGIDE_HOME/gitmux.conf"

  # Yazi config (fallback file browser)
  mkdir -p "$BIGIDE_HOME/yazi"
  cp "$BIGIDE_REPO_ROOT/config/yazi/yazi.toml"  "$BIGIDE_HOME/yazi/yazi.toml"
  cp "$BIGIDE_REPO_ROOT/config/yazi/theme.toml" "$BIGIDE_HOME/yazi/theme.toml"

  # Broot config (fallback se nvim non disponibile)
  mkdir -p "$BIGIDE_HOME/broot"
  cp "$BIGIDE_REPO_ROOT/config/broot/conf.toml" "$BIGIDE_HOME/broot/conf.toml"

  # Neovim/LazyVim config — NVIM_APPNAME=bigide legge da ~/.config/bigide/
  local nvim_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/bigide"
  mkdir -p "$nvim_config_dir"
  cp -r "$BIGIDE_REPO_ROOT/config/nvim/." "$nvim_config_dir/"

  # Plugin LazyVim — installazione headless (solo se mancante, DOPO copia config)
  local lazy_dir="${XDG_DATA_HOME:-$HOME/.local/share}/bigide/lazy/lazy.nvim"
  if [[ ! -d "$lazy_dir" ]]; then
    log "INFO" "Installazione plugin LazyVim (prima volta, attendere)..."
    NVIM_APPNAME=bigide nvim --headless "+Lazy! sync" +qa 2>/dev/null \
      || log "WARN" "LazyVim sync non completato, verrà riprovato al prossimo avvio"
  fi

  # Scripts (sovrascrivi e chmod)
  cp -r "$BIGIDE_REPO_ROOT/src/shell/scripts/" "$BIGIDE_HOME/scripts/"
  # config/scripts/ ha precedenza su src/shell/scripts/ — copia tutti con sostituzione placeholder
  for script in "$BIGIDE_REPO_ROOT/config/scripts/"*.sh; do
    [[ -f "$script" ]] || continue
    sed "s#__BIGIDE_REPO_ROOT__#$BIGIDE_REPO_ROOT#g" "$script" > "$BIGIDE_HOME/scripts/$(basename "$script")"
  done
  chmod +x "$BIGIDE_HOME/scripts"/*.sh
}

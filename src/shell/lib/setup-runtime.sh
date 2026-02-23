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
  for script in "$BIGIDE_REPO_ROOT/config/scripts/"*.sh "$BIGIDE_REPO_ROOT/config/scripts/"*.lua; do
    [[ -f "$script" ]] || continue
    sed "s#__BIGIDE_REPO_ROOT__#$BIGIDE_REPO_ROOT#g" "$script" > "$BIGIDE_HOME/scripts/$(basename "$script")"
  done
  chmod +x "$BIGIDE_HOME/scripts"/*.sh 2>/dev/null || true

  # Moduli Python (config/scripts/perplexity/)
  cp -r "$BIGIDE_REPO_ROOT/config/scripts/perplexity/" "$BIGIDE_HOME/scripts/perplexity/"
  chmod +x "$BIGIDE_HOME/scripts/perplexity/"*.py 2>/dev/null || true

  # Configurazione Ghostty dedicata BigIDE
  mkdir -p "$BIGIDE_HOME/ghostty"
  cp "$BIGIDE_REPO_ROOT/config/ghostty/config" "$BIGIDE_HOME/ghostty/config"

  # Perplexity — cartella token (non sovrascrivere se esiste già con credenziali)
  mkdir -p "$BIGIDE_HOME/perplexity"
  if [[ ! -f "$BIGIDE_HOME/perplexity/tokens.env" ]]; then
    cat > "$BIGIDE_HOME/perplexity/tokens.env" << 'TOKENS'
# Perplexity Web Session Tokens — NON committare questo file
# Ottieni il valore da: perplexity.ai → F12 → Application → Cookies
# Cookie: __Secure-next-auth.session-token  (lunga durata, non scade spesso)
PERPLEXITY_SESSION_TOKEN=""
TOKENS
    chmod 600 "$BIGIDE_HOME/perplexity/tokens.env"
  fi

  # MCP Perplexity — registra server se token configurati
  _setup_perplexity_mcp

  # BigIDE.app — bundle macOS per doppio clic
  _create_app_bundle
}

_setup_perplexity_mcp() {
  local tokens_file="$BIGIDE_HOME/perplexity/tokens.env"
  [[ -f "$tokens_file" ]] || return 0

  source "$tokens_file" 2>/dev/null || return 0
  [[ -z "$PERPLEXITY_SESSION_TOKEN" ]] && return 0

  if ! command -v claude >/dev/null 2>&1; then return 0; fi

  # Registra MCP server se non già presente
  if ! claude mcp list 2>/dev/null | grep -q "perplexity"; then
    log "INFO" "Registrazione MCP Perplexity..."
    claude mcp add perplexity-web \
      --env PERPLEXITY_SESSION_TOKEN="$PERPLEXITY_SESSION_TOKEN" \
      -- npx -y @mishamyrt/perplexity-web-api-mcp 2>/dev/null \
      || log "WARN" "Registrazione MCP Perplexity non riuscita"
  fi
}

_create_app_bundle() {
  local app_dir="$HOME/Applications/BigIDE.app"
  local macos_dir="$app_dir/Contents/MacOS"
  local ghostty_bin="/Applications/Ghostty.app/Contents/MacOS/ghostty"

  mkdir -p "$macos_dir"

  # Info.plist
  cat > "$app_dir/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>   <string>BigIDE</string>
  <key>CFBundleIdentifier</key>  <string>com.bigide.app</string>
  <key>CFBundleName</key>        <string>BigIDE</string>
  <key>CFBundleDisplayName</key> <string>BigIDE</string>
  <key>CFBundleVersion</key>     <string>1.0</string>
  <key>CFBundlePackageType</key> <string>APPL</string>
  <key>LSMinimumSystemVersion</key> <string>12.0</string>
</dict>
</plist>
PLIST

  # Launcher: apre Ghostty con la config BigIDE
  cat > "$macos_dir/BigIDE" << LAUNCHER
#!/usr/bin/env bash
GHOSTTY="$ghostty_bin"
CONFIG="\$HOME/.bigide/ghostty/config"

# Assicura che init_runtime sia stato eseguito almeno una volta
if [[ ! -f "\$CONFIG" ]]; then
  osascript -e 'display alert "BigIDE non ancora configurato." message "Esegui prima: bigide --update" as warning'
  exit 1
fi

exec "\$GHOSTTY" --config-file="\$CONFIG"
LAUNCHER

  chmod +x "$macos_dir/BigIDE"

  log "INFO" "BigIDE.app creata in ~/Applications/"
}

#!/usr/bin/env bash
# BigIDE — Toggle Chrome 50/50 con Ghostty
# prefix+c: apre NUOVA finestra Chrome a destra (50%) — sessione reale
# Ripete: chiude finestra Chrome e ripristina Ghostty fullscreen

_L() { printf '%s [EVENT] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$HOME/.bigide/logs/bigide.log" 2>/dev/null || true; }

STATE_FILE="/tmp/bigide-chrome-active"

if [[ -f "$STATE_FILE" ]]; then
    # Chrome split attivo → chiudi finestra e ripristina Ghostty
    _L "devtools: Chrome close — restore Ghostty fullscreen"
    rm -f "$STATE_FILE"
    osascript <<'AS'
-- Chiudi la finestra Chrome che abbiamo aperto
tell application "Google Chrome"
    if (count of windows) > 0 then
        close window 1
    end if
end tell
-- Ghostty → fullscreen
tell application "System Events"
    tell application process "Ghostty"
        tell window 1
            set position to {0, 0}
            set size to {9999, 9999}
        end tell
        set frontmost to true
    end tell
end tell
AS
else
    # Apri Chrome in split 50/50 (SEMPRE nuova finestra)
    _L "devtools: Chrome open 50/50 split"
    touch "$STATE_FILE"
    rm -f /tmp/bigide-safari-active
    # Chiudi eventuale Safari split
    osascript <<'AS'
tell application "System Events"
    if exists application process "Safari" then
        set visible of application process "Safari" to false
    end if
end tell
AS
    osascript <<'AS'
tell application "Finder"
    set db to bounds of window of desktop
    set sw to item 3 of db
    set sh to item 4 of db
end tell
set hw to sw div 2

-- Ghostty → metà sinistra
tell application "System Events"
    tell application process "Ghostty"
        tell window 1
            set position to {0, 0}
            set size to {hw, sh}
        end tell
    end tell
end tell

-- Chrome: SEMPRE nuova finestra (come Cmd+N)
tell application "Google Chrome"
    make new window
    delay 0.5
    activate
    -- Posiziona la nuova finestra a destra
    set bounds of window 1 to {hw, 0, sw, sh}
end tell
AS
fi

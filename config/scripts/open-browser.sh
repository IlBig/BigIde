#!/usr/bin/env bash
# BigIDE — Toggle Safari 50/50 con Ghostty
# prefix+s: apre NUOVA finestra Safari a destra (50%) — sessione reale
# Ripete: chiude finestra Safari e ripristina Ghostty fullscreen

_L() { printf '%s [EVENT] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$HOME/.bigide/logs/bigide.log" 2>/dev/null || true; }

STATE_FILE="/tmp/bigide-safari-active"

if [[ -f "$STATE_FILE" ]]; then
    # Safari split attivo → chiudi finestra e ripristina Ghostty
    _L "browser: Safari close — restore Ghostty fullscreen"
    rm -f "$STATE_FILE"
    osascript <<'AS'
-- Chiudi la finestra Safari che abbiamo aperto
tell application "Safari"
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
    # Apri Safari in split 50/50 (SEMPRE nuova finestra)
    _L "browser: Safari open 50/50 split"
    touch "$STATE_FILE"
    rm -f /tmp/bigide-chrome-active
    # Chiudi eventuale Chrome split
    osascript <<'AS'
tell application "System Events"
    if exists application process "Google Chrome" then
        set visible of application process "Google Chrome" to false
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

-- Safari: SEMPRE nuova finestra (come Cmd+N)
tell application "Safari"
    make new document
    delay 0.5
    activate
    -- Posiziona la nuova finestra (window 1 = frontmost) a destra
    set bounds of window 1 to {hw, 0, sw, sh}
end tell
AS
fi

#!/usr/bin/env bash
# BigIDE — Toggle Chrome 50/50 con Ghostty
# prefix+c: apre Chrome reale a destra (50%) con porta debug 9222
# Ripete: chiude split e ripristina Ghostty fullscreen

STATE_FILE="/tmp/bigide-chrome-active"

if [[ -f "$STATE_FILE" ]]; then
    # Chrome split attivo → ripristina Ghostty fullscreen
    rm -f "$STATE_FILE"
    osascript <<'AS'
tell application "System Events"
    -- Ghostty → fullscreen
    tell application process "Ghostty"
        tell window 1
            set position to {0, 0}
            set size to {9999, 9999}
        end tell
        set frontmost to true
    end tell
    -- Nascondi Chrome (non chiude — preserva sessione/tab)
    if exists application process "Google Chrome" then
        set visible of application process "Google Chrome" to false
    end if
end tell
AS
else
    # Apri Chrome in split 50/50
    touch "$STATE_FILE"
    # Chiudi eventuale split Safari
    rm -f /tmp/bigide-safari-active
    osascript <<'AS'
-- Dimensioni schermo
tell application "Finder"
    set db to bounds of window of desktop
    set sw to item 3 of db
    set sh to item 4 of db
end tell
set hw to sw div 2

tell application "System Events"
    -- Nascondi Safari se visibile
    if exists application process "Safari" then
        set visible of application process "Safari" to false
    end if
    -- Ghostty → metà sinistra
    tell application process "Ghostty"
        tell window 1
            set position to {0, 0}
            set size to {hw, sh}
        end tell
    end tell
end tell

-- Chrome → metà destra (con debug port per DevTools)
tell application "Google Chrome"
    activate
    if (count of windows) = 0 then make new window
    set bounds of window 1 to {hw, 0, sw, sh}
end tell
AS
fi

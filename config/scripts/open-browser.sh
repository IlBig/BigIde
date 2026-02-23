#!/usr/bin/env bash
# BigIDE — Toggle Safari 50/50 con Ghostty
# prefix+s: apre Safari reale a destra (50%) con sessione utente completa
# Ripete: chiude split e ripristina Ghostty fullscreen

STATE_FILE="/tmp/bigide-safari-active"

if [[ -f "$STATE_FILE" ]]; then
    # Safari split attivo → ripristina Ghostty fullscreen
    rm -f "$STATE_FILE"
    osascript <<'AS'
tell application "System Events"
    -- Ghostty → fullscreen (size grande, macOS clampa allo schermo)
    tell application process "Ghostty"
        tell window 1
            set position to {0, 0}
            set size to {9999, 9999}
        end tell
        set frontmost to true
    end tell
    -- Nascondi Safari (non chiude — preserva sessione/tab)
    if exists application process "Safari" then
        set visible of application process "Safari" to false
    end if
end tell
AS
else
    # Apri Safari in split 50/50
    touch "$STATE_FILE"
    # Chiudi eventuale split Chrome
    rm -f /tmp/bigide-chrome-active
    osascript <<'AS'
-- Dimensioni schermo
tell application "Finder"
    set db to bounds of window of desktop
    set sw to item 3 of db
    set sh to item 4 of db
end tell
set hw to sw div 2

tell application "System Events"
    -- Nascondi Chrome se visibile
    if exists application process "Google Chrome" then
        set visible of application process "Google Chrome" to false
    end if
    -- Ghostty → metà sinistra
    tell application process "Ghostty"
        tell window 1
            set position to {0, 0}
            set size to {hw, sh}
        end tell
    end tell
end tell

-- Safari → metà destra (sessione reale: plugin, history, autofill, cookies)
tell application "Safari"
    activate
    if (count of windows) = 0 then make new document
    set bounds of window 1 to {hw, 0, sw, sh}
end tell
AS
fi

#!/usr/bin/env bash
# BigIDE — Toggle Safari 50/50 con Ghostty
# prefix+s: apre Safari a destra, Ghostty a sinistra
# Ripete: chiude Safari e ripristina Ghostty fullscreen

_L() { printf '%s [EVENT] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$HOME/.bigide/logs/bigide.log" 2>/dev/null || true; }

STATE_FILE="/tmp/bigide-safari-active"

if [[ -f "$STATE_FILE" ]]; then
    _L "browser: Safari close — restore Ghostty fullscreen"
    rm -f "$STATE_FILE"
    osascript 2>&1 <<'AS' | while read -r line; do _L "browser/close: $line"; done
tell application "Safari"
    if (count of windows) > 0 then close window 1
end tell

tell application "Ghostty" to activate
delay 0.5

tell application "System Events"
    tell application process "Ghostty"
        set wcount to count of windows
        repeat with i from 1 to wcount
            try
                set wsize to size of window i
                set wh to item 2 of wsize
                if wh > 100 then
                    set value of attribute "AXFullScreen" of window i to true
                    log "restored fullscreen on window " & i
                    exit repeat
                end if
            end try
        end repeat
        set frontmost to true
    end tell
end tell
AS
else
    _L "browser: Safari open 50/50 split"
    touch "$STATE_FILE"
    rm -f /tmp/bigide-chrome-active
    # Chiudi eventuale Chrome split
    osascript -e 'tell application "System Events"
        if exists application process "Google Chrome" then set visible of application process "Google Chrome" to false
    end tell' 2>/dev/null || true

    osascript 2>&1 <<'AS' | while read -r line; do _L "browser/open: $line"; done
tell application "Ghostty" to activate
delay 0.5

tell application "Finder"
    set db to bounds of window of desktop
    set sw to item 3 of db
    set sh to item 4 of db
end tell
set hw to sw div 2

tell application "System Events"
    tell application process "Ghostty"
        set wcount to count of windows
        set mainWin to missing value
        repeat with i from 1 to wcount
            try
                set wsize to size of window i
                set wh to item 2 of wsize
                if wh > 100 then
                    set mainWin to i
                    exit repeat
                end if
            end try
        end repeat

        if mainWin is not missing value then
            set isFS to value of attribute "AXFullScreen" of window mainWin
            log "window " & mainWin & " fullscreen=" & isFS
            if isFS then
                set value of attribute "AXFullScreen" of window mainWin to false
                log "exiting fullscreen..."
                delay 1.5
                -- Dopo uscita fullscreen macOS riordina gli indici: ri-cerca
                set mainWin to missing value
                set wcount to count of windows
                repeat with i from 1 to wcount
                    try
                        set wsize to size of window i
                        set wh to item 2 of wsize
                        if wh > 100 then
                            set mainWin to i
                            exit repeat
                        end if
                    end try
                end repeat
                log "re-found window " & mainWin
            end if
            if mainWin is not missing value then
                tell window mainWin
                    set position to {0, 0}
                    set size to {hw, sh}
                end tell
                log "ghostty positioned left"
            else
                log "WARNING: lost window after fullscreen exit"
            end if
        else
            log "WARNING: no main window found"
        end if
    end tell
end tell

-- Safari: nuova finestra a destra
tell application "Safari"
    make new document
    delay 0.5
    activate
    set bounds of window 1 to {hw, 0, sw, sh}
end tell
log "safari positioned right"
AS
fi

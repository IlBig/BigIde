#!/usr/bin/env bash
# BigIDE — Toggle Chrome 50/50 con Ghostty
# prefix+c: apre Chrome a destra, Ghostty a sinistra
# Ripete: chiude Chrome e ripristina Ghostty fullscreen

_L() { printf '%s [EVENT] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$HOME/.bigide/logs/bigide.log" 2>/dev/null || true; }

STATE_FILE="/tmp/bigide-chrome-active"

if [[ -f "$STATE_FILE" ]]; then
    _L "devtools: Chrome close — restore Ghostty fullscreen"
    rm -f "$STATE_FILE"
    osascript 2>&1 <<'AS' | while read -r line; do _L "devtools/close: $line"; done
tell application "Google Chrome"
    if (count of windows) > 0 then close window 1
end tell

tell application "Ghostty" to activate
delay 0.5

tell application "System Events"
    tell application process "Ghostty"
        -- Trova la finestra principale e mettila fullscreen
        set wcount to count of windows
        repeat with i from 1 to wcount
            try
                set wsize to size of window i
                set ww to item 1 of wsize
                set wh to item 2 of wsize
                -- Finestra con altezza > 100 è quella principale (non tab bar)
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
    _L "devtools: Chrome open 50/50 split"
    touch "$STATE_FILE"
    rm -f /tmp/bigide-safari-active
    # Chiudi eventuale Safari split
    osascript -e 'tell application "System Events"
        if exists application process "Safari" then set visible of application process "Safari" to false
    end tell' 2>/dev/null || true

    osascript 2>&1 <<'AS' | while read -r line; do _L "devtools/open: $line"; done
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
        -- Trova la finestra principale ed esci da fullscreen se necessario
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

-- Chrome: nuova finestra a destra
tell application "Google Chrome"
    make new window
    delay 0.5
    activate
    set bounds of window 1 to {hw, 0, sw, sh}
end tell
log "chrome positioned right"
AS
fi

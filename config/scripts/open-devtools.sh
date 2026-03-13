#!/usr/bin/env bash
# BigIDE — Toggle Chrome 50/50 con Ghostty
# prefix+c: apre Chrome a destra, Ghostty a sinistra
# Ripete: chiude Chrome e ripristina Ghostty allo stato precedente

_L() { printf '%s [EVENT] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$HOME/.bigide/logs/bigide.log" 2>/dev/null || true; }
_msg() { tmux display-message -d 0 " $1" 2>/dev/null || true; }
_msg_clear() { tmux display-message "" 2>/dev/null || true; }
_resize() {
  local win_id
  win_id="$(tmux display-message -p '#{window_id}' 2>/dev/null)" || return 0
  bash "$HOME/.bigide/scripts/resize-layout.sh" "$win_id" 2>/dev/null || true
}

STATE_FILE="/tmp/bigide-chrome-active"

# Verifica che Chrome abbia davvero una finestra aperta — se no, state file è stale
if [[ -f "$STATE_FILE" ]]; then
    chrome_has_window="$(osascript -e '
tell application "System Events"
    if not (exists application process "Google Chrome") then return false
    tell application process "Google Chrome"
        if (count of windows) = 0 then return false
        return true
    end tell
end tell' 2>/dev/null)" || chrome_has_window="false"
    if [[ "$chrome_has_window" != "true" ]]; then
        _L "devtools: state file stale (Chrome non ha finestre), rimuovo"
        rm -f "$STATE_FILE"
    fi
fi

if [[ -f "$STATE_FILE" ]]; then
    was_fs="$(cat "$STATE_FILE")"
    _L "devtools: Chrome close — was_fullscreen=$was_fs"
    rm -f "$STATE_FILE"

    if [[ "$was_fs" == "true" ]]; then
        _msg "Chiusura Chrome e ripristino fullscreen..."
        osascript 2>&1 <<'AS' | while read -r line; do _L "devtools/close: $line"; done
tell application "Google Chrome"
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
        _msg "Chiusura Chrome..."
        osascript 2>&1 <<'AS' | while read -r line; do _L "devtools/close: $line"; done
tell application "Google Chrome"
    if (count of windows) > 0 then close window 1
end tell

tell application "Finder"
    set db to bounds of window of desktop
    set sw to item 3 of db
    set sh to item 4 of db
end tell

tell application "Ghostty" to activate
delay 0.3

tell application "System Events"
    tell application process "Ghostty"
        set wcount to count of windows
        repeat with i from 1 to wcount
            try
                set wsize to size of window i
                set wh to item 2 of wsize
                if wh > 100 then
                    tell window i
                        set position to {0, 0}
                        set size to {sw, sh}
                    end tell
                    log "restored maximized on window " & i
                    exit repeat
                end if
            end try
        end repeat
        set frontmost to true
    end tell
end tell
AS
    fi
    sleep 0.5
    _resize
    _msg_clear
else
    _L "devtools: Chrome open 50/50 split"
    rm -f /tmp/bigide-safari-active
    osascript -e 'tell application "System Events"
        if exists application process "Safari" then set visible of application process "Safari" to false
    end tell' 2>/dev/null || true

    # Rileva stato fullscreen
    is_fs="$(osascript -e '
tell application "System Events"
    tell application process "Ghostty"
        set wcount to count of windows
        repeat with i from 1 to wcount
            try
                set wsize to size of window i
                set wh to item 2 of wsize
                if wh > 100 then
                    return value of attribute "AXFullScreen" of window i
                end if
            end try
        end repeat
    end tell
end tell' 2>/dev/null)" || is_fs="false"

    # Salva stato
    echo "$is_fs" > "$STATE_FILE"
    _L "devtools: was_fullscreen=$is_fs"

    if [[ "$is_fs" == "true" ]]; then
        _msg "Uscita da fullscreen in corso..."
        osascript 2>&1 <<'AS' | while read -r line; do _L "devtools/open: $line"; done
tell application "Ghostty" to activate
delay 0.3
tell application "System Events"
    tell application process "Ghostty"
        set wcount to count of windows
        repeat with i from 1 to wcount
            try
                set wsize to size of window i
                set wh to item 2 of wsize
                if wh > 100 then
                    set value of attribute "AXFullScreen" of window i to false
                    log "exiting fullscreen..."
                    exit repeat
                end if
            end try
        end repeat
    end tell
end tell
AS
        # Aspetta animazione macOS
        sleep 2.5
        _msg "Posizionamento Ghostty + Chrome..."
    else
        _msg "Apertura Chrome 50/50..."
    fi

    # Posiziona Ghostty a sinistra + Chrome a destra
    osascript 2>&1 <<AS | while read -r line; do _L "devtools/open: $line"; done
tell application "Ghostty" to activate
delay 0.3

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
            tell window mainWin
                set position to {0, 0}
                set size to {hw, sh}
            end tell
            delay 0.3
            tell window mainWin
                set position to {0, 0}
                set size to {hw, sh}
            end tell
            log "ghostty positioned left"
        end if
    end tell
end tell

tell application "Google Chrome"
    make new window
    delay 0.5
    activate
    set bounds of window 1 to {hw, 0, sw, sh}
end tell
log "chrome positioned right"
AS

    sleep 0.5
    _resize
    _msg_clear
fi

#!/usr/bin/env bash
# BigIDE — Which-Key help popup
# Mostra tutti i keybinding disponibili con stile Tokyo Night
# Chiamato da tmux popup (prefix + ?)
set -euo pipefail

# ─── Colori Tokyo Night (RGB) ──────────────────────────────────────────────
B=$'\033[38;2;122;162;247m'     # blue   #7aa2f7
C=$'\033[38;2;125;207;255m'     # cyan   #7dcfff
G=$'\033[38;2;158;206;106m'     # green  #9ece6a
P=$'\033[38;2;187;154;247m'     # purple #bb9af7
W=$'\033[38;2;192;202;245m'     # white  #c0caf5
D=$'\033[38;2;86;95;137m'       # dim    #565f89
BOLD=$'\033[1m'
R=$'\033[0m'

clear

printf "\n"
printf "  ${BOLD}${B}  BigIDE — Keybinding${R}\n"
printf "  ${D}──────────────────────────────────────${R}\n"
printf "\n"
printf "  ${BOLD}${P}Navigazione${R}\n"
printf "    ${C}C-t${R}        ${W}Terminale${R}\n"
printf "    ${C}C-l${R}        ${W}Log${R}\n"
printf "    ${C}C-f${R}        ${W}File explorer${R}\n"
printf "    ${C}C-j${R}        ${W}AI${R}\n"
printf "    ${C}C-S-←→↑↓${R}  ${W}Naviga pannelli${R}\n"
printf "    ${C}C-S-1..5${R}   ${W}Pannello diretto${R}\n"
printf "    ${C}z${R}          ${W}Zoom pannello${R}\n"
printf "    ${C}e${R}          ${W}Toggle file tree${R}\n"
printf "\n"
printf "  ${BOLD}${P}Progetti${R}\n"
printf "    ${C}C-a${R}        ${W}Palette comandi${R}\n"
printf "    ${C}⌥ Tab${R}      ${W}Tab successivo${R}\n"
printf "    ${C}⌥ S-Tab${R}    ${W}Tab precedente${R}\n"
printf "    ${C}x${R}          ${W}Chiudi progetto${R}\n"
printf "\n"
printf "  ${BOLD}${P}Strumenti${R}\n"
printf "    ${C}Spazio${R}     ${W}Cerca file${R}\n"
printf "    ${C}m${R}          ${W}AI Provider${R}\n"
printf "    ${C}v${R}          ${W}Dettatura vocale${R}\n"
printf "    ${C}p${R}          ${W}Perplexity${R}\n"
printf "    ${C}s${R}          ${W}Safari split${R}\n"
printf "    ${C}c${R}          ${W}Chrome DevTools${R}\n"
printf "\n"
printf "  ${BOLD}${P}Shortcuts${R}\n"
printf "    ${C}C-s${R}        ${W}Esegui shortcut${R}\n"
printf "\n"
printf "  ${BOLD}${P}Git${R}\n"
printf "    ${C}g${R}          ${W}Lazygit${R}        ${D}Esc chiude${R}\n"
printf "    ${C}b${R}          ${W}Branch switch${R}  ${D}fzf${R}\n"
printf "\n"
printf "  ${BOLD}${P}Sessione${R}\n"
printf "    ${C}Esc${R}        ${W}Chiudi sessione${R}\n"
printf "    ${C}Q${R}          ${W}Chiudi (conferma)${R}\n"
printf "\n"
printf "  ${D}Premi un tasto per chiudere${R}\n"
printf "\n"

read -rsn1

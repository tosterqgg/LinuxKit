#!/bin/bash

# Kolory
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PKG_MANAGER=""
PKG_MANAGER_NAME=""

success() { echo -e "${GREEN}[✔]${NC} Sukces: $*"; }
error() { local e=$1; shift; echo -e "${RED}[✖]${NC} Błąd: $* ${RED}[Kod: $e]${NC}"; }
info() { echo -e "${BLUE}[ℹ]${NC} $*"; }

show_progress() {
    local progress=$1 message=$2
    local term_width=$(tput cols)
    local term_height=$(tput lines)
    local bar_width=$((term_width * 80 / 100))
    [ $bar_width -gt 60 ] && bar_width=60
    [ $bar_width -lt 20 ] && bar_width=20
    local filled=$((progress * bar_width / 100))
    local empty=$((bar_width - filled))
    clear
    tput cup $((term_height / 2 - 3)) 0
    local line_width=$((bar_width + 4))
    local padding=$(( (term_width - line_width) / 2 ))
    printf "%*s" $padding ""; echo -e "${BLUE}╔$(printf '═%.0s' $(seq 1 $line_width))╗${NC}"
    printf "%*s" $padding ""; echo -e "${BLUE}║$(printf ' %.0s' $(seq 1 $line_width))║${NC}"
    local percent_text="$progress%"
    local text_padding=$(( (line_width - ${#percent_text}) / 2 ))
    printf "%*s" $padding ""; echo -e "${BLUE}║${NC}$(printf ' %.0s' $(seq 1 $text_padding))${GREEN}${percent_text}${NC}$(printf ' %.0s' $(seq 1 $((line_width - text_padding - ${#percent_text}))))${BLUE}║${NC}"
    printf "%*s" $padding ""; echo -ne "${BLUE}║${NC}  "
    for ((i=0; i<filled; i++)); do echo -ne "${GREEN}█${NC}"; done
    for ((i=0; i<empty; i++)); do echo -ne "${NC}░${NC}"; done
    echo -e "  ${BLUE}║${NC}"
    printf "%*s" $padding ""; echo -e "${BLUE}║$(printf ' %.0s' $(seq 1 $line_width))║${NC}"
    printf "%*s" $padding ""; echo -e "${BLUE}╚$(printf '═%.0s' $(seq 1 $line_width))╝${NC}"
    [ -n "$message" ] && { echo ""; local msg_padding=$(( (term_width - ${#message}) / 2 )); printf "%*s" $msg_padding ""; echo -e "${YELLOW}$message${NC}"; }
}

check_dependencies() {
    local packages_to_check=()
    if command -v apt &> /dev/null; then
        command -v gpm &> /dev/null || packages_to_check+=("gpm")
    elif command -v pacman &> /dev/null; then
        command -v gpm &> /dev/null || packages_to_check+=("gpm")
    elif command -v pkg &> /dev/null; then
        command -v tput &> /dev/null || packages_to_check+=("ncurses-utils")
    fi
    [ ${#packages_to_check[@]} -eq 0 ] && return 0
    show_progress 0 "Przygotowanie..."; sleep 0.5
    show_progress 33 "Aktualizacja..."
    { if command -v apt &> /dev/null; then sudo apt-get update
      elif command -v pacman &> /dev/null; then sudo pacman -Sy
      elif command -v pkg &> /dev/null; then pkg update; fi } &> /dev/null
    show_progress 66 "Instalacja..."
    { if command -v apt &> /dev/null; then for p in "${packages_to_check[@]}"; do sudo apt-get install -y "$p"; done
      elif command -v pacman &> /dev/null; then for p in "${packages_to_check[@]}"; do sudo pacman -S --noconfirm "$p"; done
      elif command -v pkg &> /dev/null; then for p in "${packages_to_check[@]}"; do pkg install -y "$p"; done; fi } &> /dev/null
    show_progress 100 "Gotowe!"; sleep 1
}

select_package_manager() {
    local selected=0 max_options=8
    printf '\033[?1000h\033[?1002h\033[?1006h'
    while true; do
        clear
        echo "╔════════════════════════════════════════╗"
        echo "║   WYBIERZ MENEDŻER PAKIETÓW           ║"
        echo "╚════════════════════════════════════════╝"
        echo ""

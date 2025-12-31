#!/bin/bash

# ================== KOLORY ==================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PKG_MANAGER=""
PKG_MANAGER_NAME=""

# ================== MYSZ (NAPRAWIONA) ==================
enable_mouse()  { printf '\033[?1000h\033[?1006h'; }
disable_mouse() { printf '\033[?1000l\033[?1006l'; }

cleanup() {
    disable_mouse
    tput cnorm
}
trap cleanup EXIT

# ================== LOGI ==================
success() { echo -e "${GREEN}[✔]${NC} Sukces: $*"; }
error() { local e=$1; shift; echo -e "${RED}[✖]${NC} Error: $* ${RED}[Kod: $e]${NC}"; }
info() { echo -e "${BLUE}[ℹ]${NC} $*"; }

# ================== PROGRESS (BEZ ZMIAN) ==================
show_progress() {
    local progress=$1 message=$2
    local term_width=$(tput cols) term_height=$(tput lines)
    local bar_width=$((term_width * 80 / 100))
    [ $bar_width -gt 60 ] && bar_width=60
    [ $bar_width -lt 20 ] && bar_width=20
    local filled=$((progress * bar_width / 100)) empty=$((bar_width - filled))
    clear
    tput cup $((term_height / 2 - 3)) 0
    local line_width=$((bar_width + 4)) padding=$(( (term_width - line_width) / 2 ))
    printf "%*s" $padding ""; echo -e "${BLUE}╔$(printf '═%.0s' $(seq 1 $line_width))╗${NC}"
    printf "%*s" $padding ""; echo -e "${BLUE}║$(printf ' %.0s' $(seq 1 $line_width))║${NC}"
    local percent_text="$progress%" text_padding=$(( (line_width - ${#percent_text}) / 2 ))
    printf "%*s" $padding ""; echo -e "${BLUE}║${NC}$(printf ' %.0s' $(seq 1 $text_padding))${GREEN}${percent_text}${NC}$(printf ' %.0s' $(seq 1 $((line_width - text_padding - ${#percent_text}))))${BLUE}║${NC}"
    printf "%*s" $padding ""; echo -ne "${BLUE}║${NC}  "
    for ((i=0; i<filled; i++)); do echo -ne "${GREEN}█${NC}"; done
    for ((i=0; i<empty; i++)); do echo -ne "░"; done
    echo -e "  ${BLUE}║${NC}"
    printf "%*s" $padding ""; echo -e "${BLUE}║$(printf ' %.0s' $(seq 1 $line_width))║${NC}"
    printf "%*s" $padding ""; echo -e "${BLUE}╚$(printf '═%.0s' $(seq 1 $line_width))╝${NC}"
    [ -n "$message" ] && { echo ""; local msg_padding=$(( (term_width - ${#message}) / 2 )); printf "%*s" $msg_padding ""; echo -e "${YELLOW}$message${NC}"; }
}

# ================== AUTODETEKCJA (BEZ WINDOWS) ==================
autodetect_package_manager() {
    if command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"; PKG_MANAGER_NAME="Pacman (Arch)"
    elif command -v apt &> /dev/null; then
        PKG_MANAGER="apt"; PKG_MANAGER_NAME="APT (Debian/Ubuntu)"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"; PKG_MANAGER_NAME="DNF (Fedora)"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"; PKG_MANAGER_NAME="YUM (CentOS/RHEL)"
    elif command -v zypper &> /dev/null; then
        PKG_MANAGER="zypper"; PKG_MANAGER_NAME="Zypper (openSUSE)"
    elif command -v emerge &> /dev/null; then
        PKG_MANAGER="emerge"; PKG_MANAGER_NAME="Emerge (Gentoo)"
    elif command -v apk &> /dev/null; then
        PKG_MANAGER="apk"; PKG_MANAGER_NAME="APK (Alpine)"
    else
        clear; error 1 "Nie wykryto!"; exit 1
    fi
    clear; success "Wykryto: $PKG_MANAGER_NAME"; sleep 2
}

# ================== MENU WYBORU (IDENTYCZNE, BEZ WINDOWS) ==================
select_package_manager() {
    local selected=0 max_options=6
    enable_mouse
    while true; do
        clear
        echo "╔════════════════════════════════════╗"
        echo "║   WYBIERZ MENEDŻER PAKIETÓW        ║"
        echo "╚════════════════════════════════════╝"
        echo ""
        opts=("pacman (Arch)" "apt (Debian/Ubuntu)" "dnf (Fedora)" "yum (CentOS/RHEL)" "zypper (openSUSE)" "emerge (Gentoo)" "apk (Alpine)")
        for i in "${!opts[@]}"; do
            [[ $i -eq $selected ]] && echo -e "${GREEN}> [${opts[i]}]${NC}" || echo "  [${opts[i]}]"
        done
        echo ""; echo "Strzałki ↑↓ lub dotknij, Enter"
        read -rsn1 key
        [[ $key == $'\x1b' ]] && read -rsn2 key
        case "$key" in
            "[A") ((selected--));;
            "[B") ((selected++));;
            "")  break;;
        esac
        ((selected<0)) && selected=$max_options
        ((selected>max_options)) && selected=0
    done
    disable_mouse
    case $selected in
        0) PKG_MANAGER=pacman; PKG_MANAGER_NAME="Pacman (Arch)" ;;
        1) PKG_MANAGER=apt; PKG_MANAGER_NAME="APT (Debian/Ubuntu)" ;;
        2) PKG_MANAGER=dnf; PKG_MANAGER_NAME="DNF (Fedora)" ;;
        3) PKG_MANAGER=yum; PKG_MANAGER_NAME="YUM (CentOS/RHEL)" ;;
        4) PKG_MANAGER=zypper; PKG_MANAGER_NAME="Zypper (openSUSE)" ;;
        5) PKG_MANAGER=emerge; PKG_MANAGER_NAME="Emerge (Gentoo)" ;;
        6) PKG_MANAGER=apk; PKG_MANAGER_NAME="APK (Alpine)" ;;
    esac
}

# ================== MENU GŁÓWNE (BEZ ZMIAN) ==================
show_menu() {
    local selected=$1
    enable_mouse
    clear
    echo "╔════════════════════════════════════╗"
    echo "║     MENEDŻER PAKIETÓW              ║"
    echo "╚════════════════════════════════════╝"
    echo ""
    info "Używasz: $PKG_MANAGER_NAME"
    echo ""
    menu=("Install" "Uninstall" "Update" "Custom" "Exit")
    for i in "${!menu[@]}"; do
        [[ $i -eq $selected ]] && echo -e "${GREEN}> [${menu[i]}]${NC}" || echo "  [${menu[i]}]"
    done
    echo ""; echo "Strzałki ↑↓ lub dotknij, Enter"
}

# ================== RESZTA FUNKCJI ==================
# (logika identyczna jak u Ciebie – skrócona tu dla czytelności)
# install_package / uninstall / update / custom
# NIE ZMIENIAJĄ WYGLĄDU – tylko backend

# ================== START ==================
autodetect_package_manager || select_package_manager

sel=0
while true; do
    show_menu "$sel"
    read -rsn1 key
    [[ $key == $'\x1b' ]] && read -rsn2 key
    case "$key" in
        "[A") ((sel--));;
        "[B") ((sel++));;
        "")
            case $sel in
                0) install_package ;;
                1) uninstall_package ;;
                2) update_system ;;
                3) custom_command ;;
                4) exit 0 ;;
            esac ;;
    esac
    ((sel<0)) && sel=4
    ((sel>4)) && sel=0
done

#!/bin/bash

# Kolory
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PKG_MANAGER=""
PKG_MANAGER_NAME=""

# Funkcje komunikatów
success() { echo -e "${GREEN}[✔]${NC} Sukces: $*"; }
error() { local e=$1; shift; echo -e "${RED}[✖]${NC} Error: $* ${RED}[Kod: $e]${NC}"; }
info() { echo -e "${BLUE}[ℹ]${NC} $*"; }

# Progres
show_progress() {
    local progress=$1 message=$2
    local term_width=$(tput cols) term_height=$(tput lines)
    local bar_width=$((term_width*80/100))
    [ $bar_width -gt 60 ] && bar_width=60
    [ $bar_width -lt 20 ] && bar_width=20
    local filled=$((progress*bar_width/100))
    local empty=$((bar_width-filled))
    clear
    tput cup $((term_height/2-3)) 0
    local line_width=$((bar_width+4))
    local padding=$(((term_width-line_width)/2))
    printf "%*s" $padding ""; echo -e "${BLUE}╔$(printf '═%.0s' $(seq 1 $line_width))╗${NC}"
    printf "%*s" $padding ""; echo -e "${BLUE}║$(printf ' %.0s' $(seq 1 $line_width))║${NC}"
    local percent_text="$progress%"
    local text_padding=$(((line_width-${#percent_text})/2))
    printf "%*s" $padding ""; echo -e "${BLUE}║${NC}$(printf ' %.0s' $(seq 1 $text_padding))${GREEN}${percent_text}${NC}$(printf ' %.0s' $(seq 1 $((line_width-text_padding-${#percent_text}))))${BLUE}║${NC}"
    printf "%*s" $padding ""; echo -ne "${BLUE}║${NC}  "
    for ((i=0;i<filled;i++)); do echo -ne "${GREEN}█${NC}"; done
    for ((i=0;i<empty;i++)); do echo -ne "${NC}░${NC}"; done
    echo -e "  ${BLUE}║${NC}"
    printf "%*s" $padding ""; echo -e "${BLUE}║$(printf ' %.0s' $(seq 1 $line_width))║${NC}"
    printf "%*s" $padding ""; echo -e "${BLUE}╚$(printf '═%.0s' $(seq 1 $line_width))╝${NC}"
    [ -n "$message" ] && { echo ""; local msg_padding=$(((term_width-${#message})/2)); printf "%*s" $msg_padding ""; echo -e "${YELLOW}$message${NC}"; }
}

# Sprawdzenie zależności
check_dependencies() {
    local packages_to_check=()
    command -v gpm &>/dev/null || packages_to_check+=("gpm")
    command -v tput &>/dev/null || packages_to_check+=("ncurses-utils")
    [ ${#packages_to_check[@]} -eq 0 ] && return 0
    show_progress 0 "Przygotowanie..." && sleep 0.5
    show_progress 33 "Aktualizacja..."
    { if command -v apt &>/dev/null; then sudo apt-get update
      elif command -v pacman &>/dev/null; then sudo pacman -Sy
      elif command -v pkg &>/dev/null; then pkg update; fi } &>/dev/null
    show_progress 66 "Instalacja..."
    { if command -v apt &>/dev/null; then for p in "${packages_to_check[@]}"; do sudo apt-get install -y "$p"; done
      elif command -v pacman &>/dev/null; then for p in "${packages_to_check[@]}"; do sudo pacman -S --noconfirm "$p"; done
      elif command -v pkg &>/dev/null; then for p in "${packages_to_check[@]}"; do pkg install -y "$p"; done; fi } &>/dev/null
    show_progress 100 "Gotowe!" && sleep 1
}

# Rysowanie listy z minimalnym przerysowaniem
draw_list() {
    local -n list=$1 selected=$2 offset=$3 height=$4 last_sel_var=$5
    local total=${#list[@]}
    local end=$((offset+height))
    (( end>total )) && end=$total
    if [[ -z "${!last_sel_var}" ]]; then
        clear
        (( total>height )) && printf "%45s\n" "/\\"
        for ((i=offset;i<end;i++)); do
            if [[ $i -eq $selected ]]; then echo -e "${GREEN}> ${list[$i]}${NC}"; else echo "  ${list[$i]}"; fi
        done
        (( total>height )) && printf "%45s\n" "\\/"
        eval "$last_sel_var=$selected"
        return
    fi
    if [[ $selected -ne ${!last_sel_var} ]]; then
        tput cup $((1+${!last_sel_var}-offset)) 0
        echo "  ${list[${!last_sel_var}]}"
        tput cup $((1+selected-offset)) 0
        echo -e "${GREEN}> ${list[$selected]}${NC}"
        eval "$last_sel_var=$selected"
    fi
}

# Wybór menedżera
select_package_manager() {
    local options=("pacman (Arch)" "apt (Debian/Ubuntu)" "dnf (Fedora)" "yum (CentOS/RHEL)" "zypper (openSUSE)" "emerge (Gentoo)" "apk (Alpine)" "Autowykryj")
    local selected=0 max=${#options[@]}
    local offset=0 height=10 last_sel=""
    printf '\033[?1000h\033[?1002h\033[?1006h'
    while true; do
        draw_list options selected offset height last_sel
        IFS= read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            IFS= read -rsn1 -t 0.01 key2
            if [[ $key2 == '[' ]]; then
                IFS= read -rsn1 -t 0.01 key3
                [[ $key3 == 'A' ]] && ((selected--)) && [ $selected -lt 0 ] && selected=$((max-1))
                [[ $key3 == 'B' ]] && ((selected++)) && [ $selected -ge $max ] && selected=0
            fi
        elif [[ $key == "" ]]; then
            case $selected in
                0) PKG_MANAGER="pacman"; PKG_MANAGER_NAME="Pacman (Arch)"; break ;;
                1) PKG_MANAGER="apt"; PKG_MANAGER_NAME="APT (Debian/Ubuntu)"; break ;;
                2) PKG_MANAGER="dnf"; PKG_MANAGER_NAME="DNF (Fedora)"; break ;;
                3) PKG_MANAGER="yum"; PKG_MANAGER_NAME="YUM (CentOS/RHEL)"; break ;;
                4) PKG_MANAGER="zypper"; PKG_MANAGER_NAME="Zypper (openSUSE)"; break ;;
                5) PKG_MANAGER="emerge"; PKG_MANAGER_NAME="Emerge (Gentoo)"; break ;;
                6) PKG_MANAGER="apk"; PKG_MANAGER_NAME="APK (Alpine)"; break ;;
                7) autodetect_package_manager; break ;;
            esac
        fi
    done
    clear
    success "Wybrano: $PKG_MANAGER_NAME"
    sleep 1
}

autodetect_package_manager() {
    if command -v pacman &>/dev/null; then PKG_MANAGER="pacman"; PKG_MANAGER_NAME="Pacman (Arch)"
    elif command -v apt &>/dev/null; then PKG_MANAGER="apt"; PKG_MANAGER_NAME="APT (Debian/Ubuntu)"
    elif command -v dnf &>/dev/null; then PKG_MANAGER="dnf"; PKG_MANAGER_NAME="DNF (Fedora)"
    elif command -v yum &>/dev/null; then PKG_MANAGER="yum"; PKG_MANAGER_NAME="YUM (CentOS/RHEL)"
    elif command -v zypper &>/dev/null; then PKG_MANAGER="zypper"; PKG_MANAGER_NAME="Zypper (openSUSE)"
    elif command -v emerge &>/dev/null; then PKG_MANAGER="emerge"; PKG_MANAGER_NAME="Emerge (Gentoo)"
    elif command -v apk &>/dev/null; then PKG_MANAGER="apk"; PKG_MANAGER_NAME="APK (Alpine)"
    else clear; error 1 "Nie wykryto menedżera!"; exit 1; fi
    success "Wykryto: $PKG_MANAGER_NAME"
    sleep 1
}

# Funkcje instalacji, deinstalacji, aktualizacji, własnych komend, DE
install_package() { read -p "Nazwa pakietu: " pkg; [ -z "$pkg" ] && return; sudo $PKG_MANAGER install -y "$pkg"; }
uninstall_package() { read -p "Nazwa pakietu: " pkg; [ -z "$pkg" ] && return; sudo $PKG_MANAGER remove -y "$pkg"; }
custom_command() { read -p "Komenda: " cmd; [ -z "$cmd" ] && return; eval "$cmd"; }
update_system() { sudo $PKG_MANAGER upgrade -y; }
install_de() { echo "Instalacja DE (KDE/GNOME/XFCE) według $PKG_MANAGER"; }

# Bardzo dużo pomocnych komend
helpful_commands() {
    echo "1. Wyczyść cache"; echo "2. Usuń nieużywane"; echo "3. Lista pakietów"; echo "4. Wyszukaj pakiet"; echo "5. Info o pakiecie"
    echo "6. Napraw system"; echo "7. Historia"; echo "8. Export listy"; echo "9. Import listy"; echo "10. Sprawdź aktualizacje"
    echo "11. Downgrade"; echo "12. Blokada pakietu"; echo "13. Aktualizuj wybrany pakiet"; echo "14. Instalacja DE"; echo "15. Custom command"
}

# Menu główne
show_menu() {
    local options=("Install" "Uninstall" "Update" "Custom" "Install DE" "Pomocne komendy" "Zmień menedżer" "Exit")
    local selected=$1 offset=0 height=10 last_sel=""
    draw_list options selected offset height last_sel
}

# Minimalne odświeżanie w głównej pętli
menu_loop() {
    local options=("Install" "Uninstall" "Update" "Custom" "Install DE" "Pomocne komendy" "Zmień menedżer" "Exit")
    local selected=0 max=${#options[@]} offset=0 height=10 last_sel=""
    local old_stty=$(stty -g)
    printf '\033[?1000h\033[?1002h\033[?1006h'
    while true; do
        draw_list options selected offset height last_sel
        IFS= read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            IFS= read -rsn1 -t 0.01 key2
            [[ $key2 == '[' ]] && { IFS= read -rsn1 -t 0.01 key3
                [[ $key3 == 'A' ]] && ((selected--)) && [ $selected -lt 0 ] && selected=$((max-1))
                [[ $key3 == 'B' ]] && ((selected++)) && [ $selected -ge $max ] && selected=0
            }
        elif [[ $key == "" ]]; then
            case $selected in
                0) install_package ;;
                1) uninstall_package ;;
                2) update_system ;;
                3) custom_command ;;
                4) install_de ;;
                5) helpful_commands ;;
                6) select_package_manager ;;
                7) clear; printf '\033[?1000l\033[?1002l\033[?1006l'; info "Do widzenia!"; stty "$old_stty"; exit 0 ;;
            esac
        fi
    done
}

# Start
! command -v tput &>/dev/null && check_dependencies
select_package_manager
menu_loop

#!/bin/bash

########################
# KOLORY
########################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PKG_MANAGER=""
PKG_MANAGER_NAME=""

########################
# INFO
########################
success(){ echo -e "${GREEN}[✔]${NC} $*"; }
error(){ echo -e "${RED}[✖]${NC} $*"; }
info(){ echo -e "${BLUE}[ℹ]${NC} $*"; }

########################
# ZALEŻNOŚCI
########################
check_dependencies() {
    command -v tput &>/dev/null || {
        echo "Brak tput (ncurses). Zainstaluj ncurses."
        exit 1
    }
}

########################
# SCROLLBAR (TYLKO GDY TRZEBA)
########################
draw_list() {
    local -n items=$1
    local selected=$2
    local offset=$3
    local height=$4

    local total=${#items[@]}
    local end=$((offset + height))
    (( end > total )) && end=$total

    local show_scroll=0
    (( total > height )) && show_scroll=1

    (( show_scroll )) && printf "%60s\n" "/\\"

    for ((i=offset;i<end;i++)); do
        if [[ $i -eq $selected ]]; then
            echo -e "${GREEN}>${NC} ${items[$i]}"
        else
            echo "  ${items[$i]}"
        fi
    done

    (( show_scroll )) && printf "%60s\n" "\\/"
}

########################
# WYBÓR MANAGERA
########################
select_package_manager() {
    local options=(
        "[pacman (Arch)]"
        "[apt (Debian/Ubuntu)]"
        "[dnf (Fedora)]"
        "[yum (CentOS/RHEL)]"
        "[zypper (openSUSE)]"
        "[emerge (Gentoo)]"
        "[apk (Alpine)]"
        "[Autowykryj]"
    )

    local map=("pacman" "apt" "dnf" "yum" "zypper" "emerge" "apk" "auto")

    local selected=0 offset=0
    local height=$(( $(tput lines) - 8 ))

    while true; do
        clear
        echo "╔════════════════════════════════════════╗"
        echo "║ Wybierz manager                        ║"
        echo "╚════════════════════════════════════════╝"
        echo

        draw_list options $selected $offset $height

        read -rsn1 key
        case "$key" in
            $'\x1b')
                read -rsn2 k
                [[ $k == "[A" ]] && ((selected--))
                [[ $k == "[B" ]] && ((selected++))
                ;;
            "")
                if [[ "${map[$selected]}" == "auto" ]]; then
                    autodetect_package_manager
                else
                    PKG_MANAGER="${map[$selected]}"
                    PKG_MANAGER_NAME="${options[$selected]#[}"
                    PKG_MANAGER_NAME="${PKG_MANAGER_NAME%]}"
                fi
                return
                ;;
        esac

        (( selected < 0 )) && selected=$((${#options[@]}-1))
        (( selected >= ${#options[@]} )) && selected=0
        (( selected < offset )) && offset=$selected
        (( selected >= offset+height )) && offset=$((selected-height+1))
    done
}

########################
# AUTO WYKRYWANIE
########################
autodetect_package_manager() {
    if command -v pacman &>/dev/null; then
        PKG_MANAGER="pacman"; PKG_MANAGER_NAME="pacman (Arch)"
    elif command -v apt &>/dev/null; then
        PKG_MANAGER="apt"; PKG_MANAGER_NAME="apt (Debian/Ubuntu)"
    elif command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"; PKG_MANAGER_NAME="dnf (Fedora)"
    elif command -v zypper &>/dev/null; then
        PKG_MANAGER="zypper"; PKG_MANAGER_NAME="zypper (openSUSE)"
    elif command -v apk &>/dev/null; then
        PKG_MANAGER="apk"; PKG_MANAGER_NAME="apk (Alpine)"
    else
        error "Nie wykryto menedżera pakietów"
        exit 1
    fi
}

########################
# MENU GŁÓWNE (DLA ui.sh)
########################
show_menu() {
    local selected=$1
    clear
    echo "╔════════════════════════════════════╗"
    echo "║     MENEDŻER PAKIETÓW              ║"
    echo "╚════════════════════════════════════╝"
    echo
    info "Używasz: $PKG_MANAGER_NAME"
    echo
    local menu=(
        "[Install]"
        "[Uninstall]"
        "[Update]"
        "[Custom]"
        "[Install DE]"
        "[Pomocne komendy]"
        "[Zmień menedżer]"
        "[Exit]"
    )

    for i in "${!menu[@]}"; do
        if [[ $i -eq $selected ]]; then
            echo -e "${GREEN}>${NC} ${menu[$i]}"
        else
            echo "  ${menu[$i]}"
        fi
    done
}

########################
# AKCJE (MINIMALNE)
########################
install_package(){ read -rp "Pakiet: " p; sudo $PKG_MANAGER install "$p"; read -p "Enter..."; }
uninstall_package(){ read -rp "Pakiet: " p; sudo $PKG_MANAGER remove "$p"; read -p "Enter..."; }
update_system(){ sudo $PKG_MANAGER update && sudo $PKG_MANAGER upgrade; read -p "Enter..."; }
custom_command(){ read -rp "Komenda: " c; eval "$c"; read -p "Enter..."; }

install_de(){ info "DE – jeszcze nie ruszane"; read -p "Enter..."; }
helpful_commands(){ info "Pomocne komendy – jeszcze"; read -p "Enter..."; }

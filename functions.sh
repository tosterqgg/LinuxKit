#!/bin/bash

########################
# KOLORY
########################
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

########################
# GLOBALNE
########################
PKG_MANAGER=""
PKG_MANAGER_NAME=""

########################
# INFO
########################
info(){ echo -e "${BLUE}[i]${NC} $*"; }
error(){ echo -e "${RED}[!]${NC} $*"; }

########################
# ZALEŻNOŚCI
########################
check_dependencies() {
    command -v tput &>/dev/null || {
        echo "Brak tput (ncurses)"
        exit 1
    }
}

########################
# LISTA + SCROLLBAR
########################
draw_list() {
    local -n list=$1
    local selected=$2 offset=$3 height=$4
    local total=${#list[@]}
    local end=$((offset+height))
    (( end > total )) && end=$total
    (( total > height )) && printf "%45s\n" "/\\"

    for ((i=offset;i<end;i++)); do
        if [[ $i -eq $selected ]]; then
            echo -e "${GREEN}> ${list[$i]}${NC}"
        else
            echo "  ${list[$i]}"
        fi
    done

    (( total > height )) && printf "%45s\n" "\\/"
}

########################
# AUTO WYKRYWANIE
########################
autodetect_package_manager() {
    for m in pacman apt dnf zypper apk; do
        command -v $m &>/dev/null && {
            PKG_MANAGER="$m"
            case $m in
                pacman) PKG_MANAGER_NAME="pacman (Arch)" ;;
                apt) PKG_MANAGER_NAME="apt (Debian/Ubuntu)" ;;
                dnf) PKG_MANAGER_NAME="dnf (Fedora)" ;;
                zypper) PKG_MANAGER_NAME="zypper (openSUSE)" ;;
                apk) PKG_MANAGER_NAME="apk (Alpine)" ;;
            esac
            return
        }
    done
    error "Nie wykryto menedżera pakietów"
    exit 1
}

########################
# WYBÓR MANAGERA
########################
select_package_manager() {
    local opts=(
        "[pacman (Arch)]"
        "[apt (Debian/Ubuntu)]"
        "[dnf (Fedora)]"
        "[zypper (openSUSE)]"
        "[apk (Alpine)]"
        "[Autowykryj]"
    )
    local map=(pacman apt dnf zypper apk auto)
    local sel=0 off=0 h=$(( $(tput lines)-8 ))

    while true; do
        clear
        echo "╔════════════════════════════════════════╗"
        echo "║ Wybierz manager                        ║"
        echo "╚════════════════════════════════════════╝"
        echo
        draw_list opts $sel $off $h
        read -rsn1 k
        [[ $k == $'\x1b' ]] && read -rsn2 k2 && [[ $k2 == "[A" ]] && ((sel--)) || [[ $k2 == "[B" ]] && ((sel++))
        [[ $k == "" ]] && {
            [[ ${map[$sel]} == auto ]] && autodetect_package_manager || {
                PKG_MANAGER=${map[$sel]}
                PKG_MANAGER_NAME="${opts[$sel]#[}"; PKG_MANAGER_NAME="${PKG_MANAGER_NAME%]}"
            }
            clear; return
        }
        (( sel<0 )) && sel=$((${#opts[@]}-1))
        (( sel>=${#opts[@]} )) && sel=0
        (( sel<off )) && off=$sel
        (( sel>=off+h )) && off=$((sel-h+1))
    done
}

########################
# MENU
########################
show_menu() {
    local s=$1
    echo "╔════════════════════════════════════╗"
    echo "║     MENEDŻER PAKIETÓW              ║"
    echo "╚════════════════════════════════════╝"
    echo
    info "Menedżer: $PKG_MANAGER_NAME"
    echo
    local m=(
        "[Install]"
        "[Uninstall]"
        "[Update]"
        "[Custom command]"
        "[Install DE]"
        "[Pomocne komendy]"
        "[Zmień menedżer]"
        "[Exit]"
    )
    for i in "${!m[@]}"; do
        [[ $i -eq $s ]] && echo -e "${GREEN}> ${m[$i]}${NC}" || echo "  ${m[$i]}"
    done
}

########################
# AKCJE
########################
install_package(){ clear; read -rp "Pakiet: " p; sudo $PKG_MANAGER install "$p"; read -rp "Enter..."; }
uninstall_package(){ clear; read -rp "Pakiet: " p; sudo $PKG_MANAGER remove "$p"; read -rp "Enter..."; }
update_system(){ clear; sudo $PKG_MANAGER update && sudo $PKG_MANAGER upgrade; read -rp "Enter..."; }
custom_command(){ clear; read -rp "Komenda: " c; eval "$c"; read -rp "Enter..."; }

########################
# INSTALACJA DE
########################
install_de() {
    local de=(
        "[GNOME]"
        "[KDE Plasma]"
        "[XFCE]"
        "[LXQt]"
        "[MATE]"
        "[Powrót]"
    )
    local sel=0 off=0 h=$(( $(tput lines)-8 ))
    while true; do
        clear
        echo "╔════════════════════════════════════╗"
        echo "║ Instalacja środowiska DE           ║"
        echo "╚════════════════════════════════════╝"
        echo
        draw_list de $sel $off $h
        read -rsn1 k
        [[ $k == $'\x1b' ]] && read -rsn2 k2 && [[ $k2 == "[A" ]] && ((sel--)) || [[ $k2 == "[B" ]] && ((sel++))
        [[ $k == "" ]] && {
            clear
            case $sel in
                0) sudo $PKG_MANAGER install gnome ;;
                1) sudo $PKG_MANAGER install kde ;;
                2) sudo $PKG_MANAGER install xfce ;;
                3) sudo $PKG_MANAGER install lxqt ;;
                4) sudo $PKG_MANAGER install mate ;;
                *) return ;;
            esac
            read -rp "Enter..."; return
        }
        (( sel<0 )) && sel=$((${#de[@]}-1))
        (( sel>=${#de[@]} )) && sel=0
        (( sel<off )) && off=$sel
        (( sel>=off+h )) && off=$((sel-h+1))
    done
}

########################
# POMOCNE KOMENDY – MENU
########################
helpful_commands() {
    local cmds=(
        "[System info] uname -a"
        "[Dysk] df -h"
        "[RAM] free -h"
        "[Procesy] htop"
        "[Sieć] ip a"
        "[Porty] ss -tulpn"
        "[Logi] journalctl -xe"
        "[Usługi] systemctl status"
        "[Kernel] dmesg | less"
        "[Użytkownicy] whoami"
        "[Pakiety] $PKG_MANAGER search nano"
        "[Powrót]"
    )
    local sel=0 off=0 h=$(( $(tput lines)-8 ))
    while true; do
        clear
        echo "╔════════════════════════════════════╗"
        echo "║ Pomocne komendy                    ║"
        echo "╚════════════════════════════════════╝"
        echo
        draw_list cmds $sel $off $h
        read -rsn1 k
        [[ $k == $'\x1b' ]] && read -rsn2 k2 && [[ $k2 == "[A" ]] && ((sel--)) || [[ $k2 == "[B" ]] && ((sel++))
        [[ $k == "" ]] && {
            [[ $sel -eq $((${#cmds[@]}-1)) ]] && return
            clear
            eval "${cmds[$sel]#*] }"
            read -rp "Enter..."
        }
        (( sel<0 )) && sel=$((${#cmds[@]}-1))
        (( sel>=${#cmds[@]} )) && sel=0
        (( sel<off )) && off=$sel
        (( sel>=off+h )) && off=$((sel-h+1))
    done
}

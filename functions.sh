#!/bin/bash

# ================== KOLORY ==================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ================== ZMIENNE ==================
PKG_MANAGER=""
PKG_MANAGER_NAME=""

# ================== MYSZ ==================
enable_mouse()  { printf '\033[?1000h\033[?1006h'; }
disable_mouse() { printf '\033[?1000l\033[?1006l'; }

cleanup() {
    disable_mouse
    tput cnorm
    clear
}
trap cleanup EXIT

# ================== LOGI ==================
success() { echo -e "${GREEN}[✔]${NC} $*"; }
error()   { local e=$1; shift; echo -e "${RED}[✖]${NC} $* (${e})"; }
info()    { echo -e "${BLUE}[ℹ]${NC} $*"; }

# ================== PROGRESS ==================
show_progress() {
    local p=$1 msg=$2
    local w=$(tput cols)
    local bw=40
    local f=$((p*bw/100))
    clear
    printf "\n\n"
    printf "%*s[" $(((w-bw)/2)) ""
    printf "%0.s#" $(seq 1 $f)
    printf "%0.s." $(seq 1 $((bw-f)))
    printf "] %3s%%\n\n" "$p"
    [ -n "$msg" ] && printf "%*s%s\n" $(((w-${#msg})/2)) "" "$msg"
}

# ================== AUTODETEKCJA ==================
autodetect_package_manager() {
    if command -v pacman &>/dev/null; then
        PKG_MANAGER=pacman; PKG_MANAGER_NAME="Pacman (Arch)"
    elif command -v apt &>/dev/null; then
        PKG_MANAGER=apt; PKG_MANAGER_NAME="APT (Debian/Ubuntu)"
    elif command -v dnf &>/dev/null; then
        PKG_MANAGER=dnf; PKG_MANAGER_NAME="DNF (Fedora)"
    elif command -v yum &>/dev/null; then
        PKG_MANAGER=yum; PKG_MANAGER_NAME="YUM (RHEL/CentOS)"
    elif command -v zypper &>/dev/null; then
        PKG_MANAGER=zypper; PKG_MANAGER_NAME="Zypper (openSUSE)"
    elif command -v emerge &>/dev/null; then
        PKG_MANAGER=emerge; PKG_MANAGER_NAME="Emerge (Gentoo)"
    elif command -v apk &>/dev/null; then
        PKG_MANAGER=apk; PKG_MANAGER_NAME="APK (Alpine)"
    else
        error 1 "Nie wykryto menedżera pakietów"
        exit 1
    fi
}

# ================== MENU WYBORU ==================
select_package_manager() {
    local sel=0 max=6
    enable_mouse
    while true; do
        clear
        echo "=== WYBIERZ MENEDŻER PAKIETÓW ==="
        options=("pacman" "apt" "dnf" "yum" "zypper" "emerge" "apk")
        names=("Arch" "Debian/Ubuntu" "Fedora" "RHEL/CentOS" "openSUSE" "Gentoo" "Alpine")
        for i in "${!options[@]}"; do
            [[ $i -eq $sel ]] && echo -e "${GREEN}> ${options[i]} (${names[i]})${NC}" || echo "  ${options[i]} (${names[i]})"
        done
        read -rsn1 key
        [[ $key == $'\x1b' ]] && read -rsn2 key
        case "$key" in
            "[A") ((sel--));;
            "[B") ((sel++));;
            "")  PKG_MANAGER=${options[sel]}; PKG_MANAGER_NAME="${names[sel]}"; disable_mouse; return;;
        esac
        ((sel<0)) && sel=$max
        ((sel>max)) && sel=0
    done
}

# ================== MENU GŁÓWNE ==================
main_menu() {
    local sel=0 max=4
    enable_mouse
    while true; do
        clear
        echo "=== MENEDŻER PAKIETÓW ==="
        info "Używasz: $PKG_MANAGER_NAME"
        opts=("Install" "Uninstall" "Update" "Custom" "Exit")
        for i in "${!opts[@]}"; do
            [[ $i -eq $sel ]] && echo -e "${GREEN}> ${opts[i]}${NC}" || echo "  ${opts[i]}"
        done
        read -rsn1 key
        [[ $key == $'\x1b' ]] && read -rsn2 key
        case "$key" in
            "[A") ((sel--));;
            "[B") ((sel++));;
            "")
                case $sel in
                    0) install_package;;
                    1) uninstall_package;;
                    2) update_system;;
                    3) custom_command;;
                    4) disable_mouse; exit 0;;
                esac;;
        esac
        ((sel<0)) && sel=$max
        ((sel>max)) && sel=0
    done
}

# ================== FUNKCJE ==================
install_package() {
    clear
    read -p "Pakiet do instalacji: " p
    [ -z "$p" ] && return
    case $PKG_MANAGER in
        pacman) sudo pacman -S --noconfirm "$p" ;;
        apt) sudo apt install -y "$p" ;;
        dnf) sudo dnf install -y "$p" ;;
        yum) sudo yum install -y "$p" ;;
        zypper) sudo zypper install -y "$p" ;;
        emerge) sudo emerge "$p" ;;
        apk) sudo apk add "$p" ;;
    esac
    read -p "Enter..."
}

uninstall_package() {
    clear
    read -p "Pakiet do usunięcia: " p
    [ -z "$p" ] && return
    case $PKG_MANAGER in
        pacman) sudo pacman -R --noconfirm "$p" ;;
        apt) sudo apt remove -y "$p" ;;
        dnf) sudo dnf remove -y "$p" ;;
        yum) sudo yum remove -y "$p" ;;
        zypper) sudo zypper remove -y "$p" ;;
        emerge) sudo emerge --deselect "$p" ;;
        apk) sudo apk del "$p" ;;
    esac
    read -p "Enter..."
}

update_system() {
    clear
    case $PKG_MANAGER in
        pacman) sudo pacman -Syu --noconfirm ;;
        apt) sudo apt update && sudo apt upgrade -y ;;
        dnf) sudo dnf upgrade -y ;;
        yum) sudo yum update -y ;;
        zypper) sudo zypper update -y ;;
        emerge) sudo emerge --update --deep --newuse @world ;;
        apk) sudo apk upgrade ;;
    esac
    read -p "Enter..."
}

custom_command() {
    clear
    read -p "Komenda: " cmd
    [ -z "$cmd" ] && return
    eval "$cmd"
    read -p "Enter..."
}

# ================== START ==================
autodetect_package_manager || select_package_manager
main_menu

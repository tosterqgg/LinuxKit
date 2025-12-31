#!/bin/bash

# Kolory
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PKG_MANAGER=""
PKG_MANAGER_NAME=""

success() { echo -e "${GREEN}[✔]${NC} $*"; }
error() { local e=$1; shift; echo -e "${RED}[✖]${NC} $* ${RED}[Kod: $e]${NC}"; }
info() { echo -e "${BLUE}[ℹ]${NC} $*"; }

# Sprawdzenie zależności
check_dependencies() {
    command -v tput &> /dev/null || { error 1 "Brak tput! Zainstaluj ncurses-utils"; exit 1; }
}

# Autowykrywanie menedżera
autodetect_package_manager() {
    if command -v pacman &> /dev/null; then PKG_MANAGER="pacman"; PKG_MANAGER_NAME="Pacman (Arch)"
    elif command -v apt &> /dev/null; then PKG_MANAGER="apt"; PKG_MANAGER_NAME="APT (Debian/Ubuntu)"
    elif command -v dnf &> /dev/null; then PKG_MANAGER="dnf"; PKG_MANAGER_NAME="DNF (Fedora)"
    elif command -v yum &> /dev/null; then PKG_MANAGER="yum"; PKG_MANAGER_NAME="YUM (CentOS/RHEL)"
    elif command -v zypper &> /dev/null; then PKG_MANAGER="zypper"; PKG_MANAGER_NAME="Zypper (openSUSE)"
    elif command -v emerge &> /dev/null; then PKG_MANAGER="emerge"; PKG_MANAGER_NAME="Emerge (Gentoo)"
    elif command -v apk &> /dev/null; then PKG_MANAGER="apk"; PKG_MANAGER_NAME="APK (Alpine)"
    else error 1 "Nie wykryto menedżera pakietów!"; exit 1; fi
    clear
    success "Wykryto: $PKG_MANAGER_NAME"
    sleep 1
}

# Funkcja do przewijanych list
show_scrollable_list() {
    local options=("${!1}")
    local selected=0
    local scroll=0
    local max_display=$(tput lines)
    ((max_display-=6))

    while true; do
        clear
        echo "╔════════════════════════════════════════╗"
        echo "║ Wybierz opcję                           ║"
        echo "╚════════════════════════════════════════╝"
        local end=$((scroll+max_display))
        ((end> ${#options[@]} )) && end=${#options[@]}
        for i in $(seq $scroll $((end-1))); do
            if [ $i -eq $selected ]; then
                echo -e "${GREEN}> [${options[$i]}]${NC}"
            else
                echo "  [${options[$i]}]"
            fi
        done
        echo ""
        echo "↑↓, Enter, q=wyjście"

        IFS= read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            IFS= read -rsn1 -t 0.01 key2
            if [[ $key2 == '[' ]]; then
                IFS= read -rsn1 -t 0.01 key3
                if [[ $key3 == 'A' ]]; then ((selected--)); [ $selected -lt 0 ] && selected=$((${#options[@]}-1)); fi
                if [[ $key3 == 'B' ]]; then ((selected++)); [ $selected -ge ${#options[@]} ] && selected=0; fi
            fi
        elif [[ $key == "" ]]; then
            echo $selected
            return
        elif [[ $key == "q" ]]; then
            return 255
        fi

        if [ $selected -lt $scroll ]; then scroll=$selected; fi
        if [ $selected -ge $((scroll+max_display)) ]; then scroll=$((selected-max_display+1)); fi
    done
}

# Wybór menedżera pakietów
select_package_manager() {
    local options=("pacman (Arch)" "apt (Debian/Ubuntu)" "dnf (Fedora)" "yum (CentOS/RHEL)" "zypper (openSUSE)" "emerge (Gentoo)" "apk (Alpine)" "Autowykryj")
    local sel=$(show_scrollable_list options[@])
    case $sel in
        0) PKG_MANAGER="pacman"; PKG_MANAGER_NAME="Pacman (Arch)";;
        1) PKG_MANAGER="apt"; PKG_MANAGER_NAME="APT (Debian/Ubuntu)";;
        2) PKG_MANAGER="dnf"; PKG_MANAGER_NAME="DNF (Fedora)";;
        3) PKG_MANAGER="yum"; PKG_MANAGER_NAME="YUM (CentOS/RHEL)";;
        4) PKG_MANAGER="zypper"; PKG_MANAGER_NAME="Zypper (openSUSE)";;
        5) PKG_MANAGER="emerge"; PKG_MANAGER_NAME="Emerge (Gentoo)";;
        6) PKG_MANAGER="apk"; PKG_MANAGER_NAME="APK (Alpine)";;
        7) autodetect_package_manager;;
        255) exit 0;;
    esac
    clear
    success "Wybrano: $PKG_MANAGER_NAME"
    sleep 1
}

# Operacje na pakietach
install_package() {
    read -p "Nazwa pakietu do instalacji: " pkg
    case $PKG_MANAGER in
        pacman) sudo pacman -S "$pkg";;
        apt) sudo apt install -y "$pkg";;
        dnf) sudo dnf install -y "$pkg";;
        yum) sudo yum install -y "$pkg";;
        zypper) sudo zypper install -y "$pkg";;
        emerge) sudo emerge "$pkg";;
        apk) sudo apk add "$pkg";;
        *) error 1 "Nieznany menedżer!";;
    esac
    read -p "Enter..."
}

uninstall_package() {
    read -p "Nazwa pakietu do odinstalowania: " pkg
    case $PKG_MANAGER in
        pacman) sudo pacman -R "$pkg";;
        apt) sudo apt remove -y "$pkg";;
        dnf) sudo dnf remove -y "$pkg";;
        yum) sudo yum remove -y "$pkg";;
        zypper) sudo zypper remove -y "$pkg";;
        emerge) sudo emerge --unmerge "$pkg";;
        apk) sudo apk del "$pkg";;
        *) error 1 "Nieznany menedżer!";;
    esac
    read -p "Enter..."
}

update_system() {
    case $PKG_MANAGER in
        pacman) sudo pacman -Syu;;
        apt) sudo apt update && sudo apt upgrade -y;;
        dnf) sudo dnf upgrade -y;;
        yum) sudo yum update -y;;
        zypper) sudo zypper update -y;;
        emerge) sudo emerge --update --deep --with-bdeps=y @world;;
        apk) sudo apk update && sudo apk upgrade;;
        *) error 1 "Nieznany menedżer!";;
    esac
    read -p "Enter..."
}

search_package() {
    read -p "Nazwa pakietu do wyszukania: " pkg
    case $PKG_MANAGER in
        pacman) pacman -Ss "$pkg";;
        apt) apt search "$pkg";;
        dnf) dnf search "$pkg";;
        yum) yum search "$pkg";;
        zypper) zypper search "$pkg";;
        emerge) emerge -s "$pkg";;
        apk) apk search "$pkg";;
        *) error 1 "Nieznany menedżer!";;
    esac
    read -p "Enter..."
}

# Własne komendy
custom_command() { read -p "Komenda: " cmd; eval "$cmd"; read -p "Enter..."; }
install_de() { info "Instalacja DE (przykład)..."; read -p "Enter..."; }

helpful_commands() {
    local options=("Wyczyść cache" "Lista pakietów" "Wyszukaj pakiet" "Info o pakiecie" "Historia pakietów" "Sprawdź aktualizacje" "Powrót")
    local sel=$(show_scrollable_list options[@])
    case $sel in
        0) case $PKG_MANAGER in
                pacman) sudo pacman -Scc;;
                apt) sudo apt clean;;
                dnf|yum) sudo $PKG_MANAGER clean all;;
                zypper) sudo zypper clean;;
                apk) sudo apk cache clean;;
                emerge) sudo emerge --depclean;;
           esac; read -p "Enter...";;
        1) case $PKG_MANAGER in
                pacman) pacman -Q;;
                apt) apt list --installed;;
                dnf) dnf list installed;;
                yum) yum list installed;;
                zypper) zypper se -i;;
                apk) apk info;;
                emerge) equery list '*' ;;
           esac; read -p "Enter...";;
        2) search_package;;
        3) read -p "Pakiet: " pkg; case $PKG_MANAGER in
                pacman) pacman -Qi "$pkg";;
                apt) apt show "$pkg";;
                dnf) dnf info "$pkg";;
                yum) yum info "$pkg";;
                zypper) zypper info "$pkg";;
                apk) apk info "$pkg";;
                emerge) equery -q "$pkg";;
           esac; read -p "Enter...";;
        4) info "Historia pakietów... (symulacja)"; read -p "Enter...";;
        5) update_system;;
        6|255) return;;
    esac
}

# Menu główne
show_menu() {
    local options=("Zainstaluj pakiet" "Odinstaluj pakiet" "Aktualizuj system" "Własne polecenie" "Zainstaluj DE" "Pomocne komendy" "Wybierz menedżera pakietów" "Wyjdź")
    local sel=$(show_scrollable_list options[@])
    case $sel in
        0) install_package ;;
        1) uninstall_package ;;
        2) update_system ;;
        3) custom_command ;;
        4) install_de ;;
        5) helpful_commands ;;
        6) select_package_manager ;;
        7|255) clear; info "Do widzenia!"; exit 0 ;;
    esac
}

# Start
check_dependencies
select_package_manager
while true; do
    show_menu
done

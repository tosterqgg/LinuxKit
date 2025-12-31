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

# Sprawdzenie zależności
check_dependencies() {
    local packages_to_check=()
    command -v tput &> /dev/null || packages_to_check+=("ncurses-utils")
    [ ${#packages_to_check[@]} -eq 0 ] && return 0
    show_progress 0 "Przygotowanie..."
    sleep 0.5
    show_progress 100 "Gotowe!"
    sleep 0.5
}

# Prosty pasek postępu
show_progress() {
    local progress=$1 message=$2
    echo -e "${BLUE}[${progress}%]${NC} $message"
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
    else error 1 "Nie wykryto żadnego menedżera!"; exit 1; fi
    clear
    success "Wykryto: $PKG_MANAGER_NAME"
    sleep 1
}

# Wybór menedżera
select_package_manager() {
    local selected=0
    local max_options=7
    printf '\033[?1000h\033[?1002h\033[?1006h'
    while true; do
        clear
        echo "╔════════════════════════════════════════╗"
        echo "║   WYBIERZ MENEDŻER PAKIETÓW           ║"
        echo "╚════════════════════════════════════════╝"
        echo ""
        local options=("pacman (Arch)" "apt (Debian/Ubuntu)" "dnf (Fedora)" "yum (CentOS/RHEL)" "zypper (openSUSE)" "emerge (Gentoo)" "apk (Alpine)" "Autowykryj")
        for i in "${!options[@]}"; do
            [ $i -eq $selected ] && echo -e "${GREEN}> [${options[$i]}]${NC}" || echo "  [${options[$i]}]"
        done
        echo ""
        echo "Strzałki ↑↓, Enter"
        IFS= read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            IFS= read -rsn1 -t 0.01 key2
            if [[ $key2 == '[' ]]; then
                IFS= read -rsn1 -t 0.01 key3
                if [[ $key3 == 'A' ]]; then ((selected--)); [ $selected -lt 0 ] && selected=$max_options
                elif [[ $key3 == 'B' ]]; then ((selected++)); [ $selected -gt $max_options ] && selected=0
                fi
            fi
        elif [[ $key == "" ]]; then
            case $selected in
                0) PKG_MANAGER="pacman"; PKG_MANAGER_NAME="Pacman (Arch)"; return ;;
                1) PKG_MANAGER="apt"; PKG_MANAGER_NAME="APT (Debian/Ubuntu)"; return ;;
                2) PKG_MANAGER="dnf"; PKG_MANAGER_NAME="DNF (Fedora)"; return ;;
                3) PKG_MANAGER="yum"; PKG_MANAGER_NAME="YUM (CentOS/RHEL)"; return ;;
                4) PKG_MANAGER="zypper"; PKG_MANAGER_NAME="Zypper (openSUSE)"; return ;;
                5) PKG_MANAGER="emerge"; PKG_MANAGER_NAME="Emerge (Gentoo)"; return ;;
                6) PKG_MANAGER="apk"; PKG_MANAGER_NAME="APK (Alpine)"; return ;;
                7) autodetect_package_manager; return ;;
            esac
        fi
    done
}

# Prosta funkcja menu głównego
show_menu() {
    local selected=$1
    local options=("Zainstaluj pakiet" "Odinstaluj pakiet" "Aktualizuj system" "Własne polecenie" "Zainstaluj DE" "Pomocne komendy" "Wybierz menedżera pakietów" "Wyjdź")
    clear
    echo "╔════════════════════════════════════════╗"
    echo "║              MENU GŁÓWNE               ║"
    echo "╚════════════════════════════════════════╝"
    for i in "${!options[@]}"; do
        [ $i -eq $selected ] && echo -e "${GREEN}> [${options[$i]}]${NC}" || echo "  [${options[$i]}]"
    done
}

# Funkcje akcji (przykłady)
install_package() { info "Instalacja pakietu..."; sleep 1; }
uninstall_package() { info "Odinstalowywanie pakietu..."; sleep 1; }
update_system() { info "Aktualizacja systemu..."; sleep 1; }
custom_command() { info "Uruchamianie własnego polecenia..."; sleep 1; }
install_de() { info "Instalacja środowiska graficznego..."; sleep 1; }
helpful_commands() { info "Wyświetlanie przydatnych komend..."; sleep 1; }

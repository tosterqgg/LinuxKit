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
error() { local e=$1; shift; echo -e "${RED}[✖]${NC} Error: $* ${RED}[Kod: $e]${NC}"; }
info() { echo -e "${BLUE}[ℹ]${NC} $*"; }

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
    while true; do
        clear; echo "╔════════════════════════════════════╗"; echo "║   WYBIERZ MENEDŻER PAKIETÓW        ║"; echo "╚════════════════════════════════════╝"; echo ""
        [ $selected -eq 0 ] && echo -e "${GREEN}> [pacman (Arch)]${NC}" || echo "  [pacman (Arch)]"
        [ $selected -eq 1 ] && echo -e "${GREEN}> [apt (Debian/Ubuntu)]${NC}" || echo "  [apt (Debian/Ubuntu)]"
        [ $selected -eq 2 ] && echo -e "${GREEN}> [dnf (Fedora)]${NC}" || echo "  [dnf (Fedora)]"
        [ $selected -eq 3 ] && echo -e "${GREEN}> [yum (CentOS/RHEL)]${NC}" || echo "  [yum (CentOS/RHEL)]"
        [ $selected -eq 4 ] && echo -e "${GREEN}> [zypper (openSUSE)]${NC}" || echo "  [zypper (openSUSE)]"
        [ $selected -eq 5 ] && echo -e "${GREEN}> [emerge (Gentoo)]${NC}" || echo "  [emerge (Gentoo)]"
        [ $selected -eq 6 ] && echo -e "${GREEN}> [apk (Alpine)]${NC}" || echo "  [apk (Alpine)]"
        [ $selected -eq 7 ] && echo -e "${GREEN}> [winget (Windows)]${NC}" || echo "  [winget (Windows)]"
        [ $selected -eq 8 ] && echo -e "${GREEN}> [Autowykryj]${NC}" || echo "  [Autowykryj]"
        echo ""; echo "Strzałki ↑↓, Enter"
        IFS= read -rsn1 key
        if [[ $key == $'\x1b' ]]; then read -rsn2 -t 0.1 key
            case "$key" in '[A') ((selected--)); [ $selected -lt 0 ] && selected=$max_options ;;
                           '[B') ((selected++)); [ $selected -gt $max_options ] && selected=0 ;; esac
        elif [[ $key == "" ]]; then
            case $selected in
                0) PKG_MANAGER="pacman"; PKG_MANAGER_NAME="Pacman (Arch)"; return ;;
                1) PKG_MANAGER="apt"; PKG_MANAGER_NAME="APT (Debian/Ubuntu)"; return ;;
                2) PKG_MANAGER="dnf"; PKG_MANAGER_NAME="DNF (Fedora)"; return ;;
                3) PKG_MANAGER="yum"; PKG_MANAGER_NAME="YUM (CentOS/RHEL)"; return ;;
                4) PKG_MANAGER="zypper"; PKG_MANAGER_NAME="Zypper (openSUSE)"; return ;;
                5) PKG_MANAGER="emerge"; PKG_MANAGER_NAME="Emerge (Gentoo)"; return ;;
                6) PKG_MANAGER="apk"; PKG_MANAGER_NAME="APK (Alpine)"; return ;;
                7) PKG_MANAGER="winget"; PKG_MANAGER_NAME="Winget (Windows)"; return ;;
                8) autodetect_package_manager; return ;;
            esac
        fi
    done
}

autodetect_package_manager() {
    if command -v pacman &> /dev/null; then PKG_MANAGER="pacman"; PKG_MANAGER_NAME="Pacman (Arch)"
    elif command -v apt &> /dev/null; then PKG_MANAGER="apt"; PKG_MANAGER_NAME="APT (Debian/Ubuntu)"
    elif command -v dnf &> /dev/null; then PKG_MANAGER="dnf"; PKG_MANAGER_NAME="DNF (Fedora)"
    elif command -v yum &> /dev/null; then PKG_MANAGER="yum"; PKG_MANAGER_NAME="YUM (CentOS/RHEL)"
    elif command -v zypper &> /dev/null; then PKG_MANAGER="zypper"; PKG_MANAGER_NAME="Zypper (openSUSE)"
    elif command -v emerge &> /dev/null; then PKG_MANAGER="emerge"; PKG_MANAGER_NAME="Emerge (Gentoo)"
    elif command -v apk &> /dev/null; then PKG_MANAGER="apk"; PKG_MANAGER_NAME="APK (Alpine)"
    elif command -v winget &> /dev/null; then PKG_MANAGER="winget"; PKG_MANAGER_NAME="Winget (Windows)"
    else clear; error 1 "Nie wykryto!"; exit 1; fi
    clear; success "Wykryto: $PKG_MANAGER_NAME"; sleep 2
}

show_menu() {
    local selected=$1; clear; printf '\033[?1000h\033[?1002h\033[?1006h'
    echo "╔════════════════════════════════════╗"; echo "║     MENEDŻER PAKIETÓW              ║"; echo "╚════════════════════════════════════╝"; echo ""
    info "Używasz: $PKG_MANAGER_NAME"; echo ""
    [ $selected -eq 0 ] && echo -e "${GREEN}> [Install]${NC}" || echo "  [Install]"
    [ $selected -eq 1 ] && echo -e "${GREEN}> [Uninstall]${NC}" || echo "  [Uninstall]"
    [ $selected -eq 2 ] && echo -e "${GREEN}> [Update]${NC}" || echo "  [Update]"
    [ $selected -eq 3 ] && echo -e "${GREEN}> [Custom]${NC}" || echo "  [Custom]"
    [ $selected -eq 4 ] && echo -e "${GREEN}> [Install DE]${NC}" || echo "  [Install DE]"
    [ $selected -eq 5 ] && echo -e "${GREEN}> [Pomocne komendy]${NC}" || echo "  [Pomocne komendy]"
    [ $selected -eq 6 ] && echo -e "${GREEN}> [Zmień menedżer]${NC}" || echo "  [Zmień menedżer]"
    [ $selected -eq 7 ] && echo -e "${GREEN}> [Exit]${NC}" || echo "  [Exit]"
    echo ""; echo "Strzałki ↑↓ lub dotknij, Enter"
}

install_package() {
    clear; echo "╔════════════════════════════════════╗"; echo "║         INSTALACJA PAKIETU         ║"; echo "╚════════════════════════════════════╝"; echo ""
    read -p "Nazwa: " package
    [ -z "$package" ] && { error 1 "Brak nazwy"; echo ""; read -p "Enter..."; return 1; }
    info "Instaluję: $package"
    case $PKG_MANAGER in
        pacman) sudo pacman -S "$package" --noconfirm ;;
        apt) sudo apt install -y "$package" ;;
        dnf) sudo dnf install -y "$package" ;;
        yum) sudo yum install -y "$package" ;;
        zypper) sudo zypper install -y "$package" ;;
        emerge) sudo emerge "$package" ;;
        apk) sudo apk add "$package" ;;
        winget) winget install "$package" --accept-source-agreements --accept-package-agreements ;;
    esac
    local e=$?; echo ""; [ $e -eq 0 ] && success "Zainstalowano" || error $e "Błąd"
    echo ""; read -p "Enter..."
}

uninstall_package() {
    clear; echo "╔════════════════════════════════════╗"; echo "║        DEINSTALACJA PAKIETU        ║"; echo "╚════════════════════════════════════╝"; echo ""
    read -p "Nazwa: " package
    [ -z "$package" ] && { error 1 "Brak nazwy"; echo ""; read -p "Enter..."; return 1; }
    info "Usuwam: $package"
    case $PKG_MANAGER in
        pacman) sudo pacman -R "$package" --noconfirm ;;
        apt) sudo apt remove -y "$package" ;;
        dnf) sudo dnf remove -y "$package" ;;
        yum) sudo yum remove -y "$package" ;;
        zypper) sudo zypper remove -y "$package" ;;
        emerge) sudo emerge --deselect "$package" ;;
        apk) sudo apk del "$package" ;;
        winget) winget uninstall "$package" ;;
    esac
    local e=$?; echo ""; [ $e -eq 0 ] && success "Usunięto" || error $e "Błąd"
    echo ""; read -p "Enter..."
}

custom_command() {
    clear; echo "╔════════════════════════════════════╗"; echo "║        WŁASNA KOMENDA              ║"; echo "╚════════════════════════════════════╝"; echo ""
    read -p "Komenda: " command
    [ -z "$command" ] && { error 1 "Brak komendy"; echo ""; read -p "Enter..."; return 1; }
    info "Wykonuję: $command"; echo ""; eval "$command"; local e=$?
    echo ""; [ $e -eq 0 ] && success "Wykonano" || error $e "Błąd"
    echo ""; read -p "Enter..."
}
update_system() {
    local sel=0 max=1
    while true; do
        clear; echo "╔════════════════════════════════════╗"; echo "║       AKTUALIZACJA SYSTEMU         ║"; echo "╚════════════════════════════════════╝"; echo ""
        [ $sel -eq 0 ] && echo -e "${GREEN}> [Cały system]${NC}" || echo "  [Cały system]"
        [ $sel -eq 1 ] && echo -e "${GREEN}> [Wybrany pakiet]${NC}" || echo "  [Wybrany pakiet]"
        echo ""; echo "↑↓, Enter, q=wyjście"
        IFS= read -rsn1 key
        if [[ $key == $'\x1b' ]]; then read -rsn2 -t 0.1 key
            case "$key" in '[A') ((sel--)); [ $sel -lt 0 ] && sel=$max ;; '[B') ((sel++)); [ $sel -gt $max ] && sel=0 ;; esac
        elif [[ $key == "q" ]] || [[ $key == "Q" ]]; then return
        elif [[ $key == "" ]]; then
            clear
            if [ $sel -eq 0 ]; then
                echo "╔════════════════════════════════════╗"; echo "║     AKTUALIZACJA CAŁEGO SYSTEMU    ║"; echo "╚════════════════════════════════════╝"; echo ""
                info "Aktualizuję..."
                case $PKG_MANAGER in
                    pacman) sudo pacman -Syu --noconfirm ;;
                    apt) sudo apt update && sudo apt upgrade -y ;;
                    dnf) sudo dnf upgrade -y ;;
                    yum) sudo yum update -y ;;
                    zypper) sudo zypper update -y ;;
                    emerge) sudo emerge --update --deep --newuse @world ;;
                    apk) sudo apk upgrade ;;
                    winget) winget upgrade --all ;;
                esac
                local e=$?; echo ""; [ $e -eq 0 ] || [ $e -eq 100 ] && success "Zaktualizowano!" || error $e "Błąd"
                echo ""; read -p "Enter..."
            else
                update_specific_package
            fi
        fi
    done
}

update_specific_package() {
    local packages=() all_packages=() selected=0 search_term="" scroll_offset=0 max_display=10
    info "Ładowanie..."
    case $PKG_MANAGER in
        pacman) mapfile -t all_packages < <(checkupdates 2>/dev/null | awk '{print $1}') ;;
        apt) mapfile -t all_packages < <(apt list --upgradable 2>/dev/null | grep -v "Listing" | cut -d'/' -f1) ;;
        dnf|yum) mapfile -t all_packages < <($PKG_MANAGER check-update 2>/dev/null | awk '{print $1}' | grep -v "^$") ;;
        winget) mapfile -t all_packages < <(winget upgrade 2>/dev/null | grep -v "^Name" | grep -v "^-" | awk '{print $1}' | grep -v "^$") ;;
        *) all_packages=() ;;
    esac
    while true; do
        clear; echo "╔════════════════════════════════════╗"; echo "║   AKTUALIZACJA WYBRANEGO PAKIETU   ║"; echo "╚════════════════════════════════════╝"; echo ""
        if [ -z "$search_term" ]; then packages=("${all_packages[@]}")
        else packages=(); for pkg in "${all_packages[@]}"; do [[ "$pkg" == *"$search_term"* ]] && packages+=("$pkg"); done; fi
        if [ ${#packages[@]} -eq 0 ]; then
            info "Brak aktualizacji"; [ -n "$search_term" ] && info "dla: '$search_term'"
            echo ""; echo "════════════════════════════════════"; echo "Wyszukaj: ${search_term}█"; echo "════════════════════════════════════"
            echo ""; echo "ESC=wyjście, Backspace=wyczyść"
            IFS= read -rsn1 key
            if [[ $key == $'\x1b' ]]; then read -rsn2 -t 0.1 key2; [ "$key2" == "" ] && return
            elif [[ $key == $'\x7f' ]]; then search_term="${search_term%?}"
            elif [[ $key =~ [a-zA-Z0-9\-] ]]; then search_term="${search_term}${key}"; selected=0; scroll_offset=0; fi
            continue
        fi
        local total=${#packages[@]}
        [ $selected -ge $total ] && selected=$((total - 1)); [ $selected -lt 0 ] && selected=0
        [ $selected -lt $scroll_offset ] && scroll_offset=$selected
        [ $selected -ge $((scroll_offset + max_display)) ] && scroll_offset=$((selected - max_display + 1))
        [ $scroll_offset -lt 0 ] && scroll_offset=0
        local end=$((scroll_offset + max_display)); [ $end -gt $total ] && end=$total
        info "Dostępne: $total"; echo ""
        for ((i=scroll_offset; i<end; i++)); do
            [ $i -eq $selected ] && echo -e "${GREEN}> ${packages[$i]}${NC}" || echo "  ${packages[$i]}"
        done
        [ $total -gt $max_display ] && { echo ""; info "Pozycja: $((selected + 1))/$total"; }
        echo ""; echo "════════════════════════════════════"; echo "Wyszukaj: ${search_term}█"; echo "════════════════════════════════════"
        echo ""; echo "↑↓, Enter, ESC, Backspace"
        IFS= read -rsn1 key
        if [[ $key == $'\x1b' ]]; then read -rsn2 -t 0.1 key
            case "$key" in '[A') ((selected--)); [ $selected -lt 0 ] && selected=$((total - 1)) ;;
                           '[B') ((selected++)); [ $selected -ge $total ] && selected=0 ;;
                           '') return ;; esac
        elif [[ $key == "" ]]; then
            clear; local pkg="${packages[$selected]}"
            echo "╔════════════════════════════════════╗"; echo "║      AKTUALIZACJA PAKIETU          ║"; echo "╚════════════════════════════════════╝"; echo ""
            info "Aktualizuję: $pkg"; echo ""
            case $PKG_MANAGER in
                pacman) sudo pacman -S "$pkg" --noconfirm ;;
                apt) sudo apt install --only-upgrade "$pkg" -y ;;
                dnf) sudo dnf upgrade "$pkg" -y ;;
                yum) sudo yum update "$pkg" -y ;;
                zypper) sudo zypper update "$pkg" -y ;;
                winget) winget upgrade "$pkg" ;;
                *) error 1 "Nie wspierane" ;;
            esac
            local e=$?; echo ""; [ $e -eq 0 ] && success "Zaktualizowano '$pkg'" || error $e "Błąd"
            echo ""; read -p "Enter..."; return
        elif [[ $key == $'\x7f' ]]; then search_term="${search_term%?}"; selected=0; scroll_offset=0
        elif [[ $key =~ [a-zA-Z0-9\-] ]]; then search_term="${search_term}${key}"; selected=0; scroll_offset=0; fi
    done
}

install_de() {
    local sel=0 max=2
    while true; do
        clear; echo "╔════════════════════════════════════╗"; echo "║    INSTALACJA ŚRODOWISKA DESKTOP   ║"; echo "╚════════════════════════════════════╝"; echo ""
        [ $sel -eq 0 ] && echo -e "${GREEN}> [KDE Plasma]${NC}" || echo "  [KDE Plasma]"
        [ $sel -eq 1 ] && echo -e "${GREEN}> [GNOME]${NC}" || echo "  [GNOME]"
        [ $sel -eq 2 ] && echo -e "${GREEN}> [XFCE]${NC}" || echo "  [XFCE]"
        echo ""; echo "↑↓, Enter, q=wyjście"
        IFS= read -rsn1 key
        if [[ $key == $'\x1b' ]]; then read -rsn2 -t 0.1 key
            case "$key" in '[A') ((sel--)); [ $sel -lt 0 ] && sel=$max ;; '[B') ((sel++)); [ $sel -gt $max ] && sel=0 ;; esac
        elif [[ $key == "q" ]] || [[ $key == "Q" ]]; then return
        elif [[ $key == "" ]]; then
            clear
            case $sel in
                0) echo "═══ KDE PLASMA ═══"; echo ""; info "Instaluję..."
                   case $PKG_MANAGER in
                       pacman) sudo pacman -S --noconfirm plasma kde-applications sddm; sudo systemctl enable sddm ;;
                       apt) sudo apt install -y kde-plasma-desktop sddm; sudo systemctl enable sddm ;;
                       dnf) sudo dnf install -y @kde-desktop-environment sddm; sudo systemctl enable sddm ;;
                       *) error 1 "Nie wspierane" ;; esac
                   [ $? -eq 0 ] && success "Zainstalowano!" || error $? "Błąd" ;;
                1) echo "═══ GNOME ═══"; echo ""; info "Instaluję..."
                   case $PKG_MANAGER in
                       pacman) sudo pacman -S --noconfirm gnome gnome-extra gdm; sudo systemctl enable gdm ;;
                       apt) sudo apt install -y gnome gdm3; sudo systemctl enable gdm3 ;;
                       dnf) sudo dnf install -y @gnome-desktop gdm; sudo systemctl enable gdm ;;
                       *) error 1 "Nie wspierane" ;; esac
                   [ $? -eq 0 ] && success "Zainstalowano!" || error $? "Błąd" ;;
                2) echo "═══ XFCE ═══"; echo ""; info "Instaluję..."
                   case $PKG_MANAGER in
                       pacman) sudo pacman -S --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter; sudo systemctl enable lightdm ;;
                       apt) sudo apt install -y xfce4 xfce4-goodies lightdm; sudo systemctl enable lightdm ;;
                       dnf) sudo dnf install -y @xfce-desktop-environment lightdm; sudo systemctl enable lightdm ;;
                       *) error 1 "Nie wspierane" ;; esac
                   [ $? -eq 0 ] && success "Zainstalowano!" || error $? "Błąd" ;;
            esac
            echo ""; read -p "Enter..."
        fi
    done
}
helpful_commands() {
    local sel=0 max=12
    while true; do
        clear; echo "╔════════════════════════════════════╗"; echo "║        POMOCNE KOMENDY             ║"; echo "╚════════════════════════════════════╝"; echo ""
        [ $sel -eq 0 ] && echo -e "${GREEN}> [Wyczyść cache]${NC}" || echo "  [Wyczyść cache]"
        [ $sel -eq 1 ] && echo -e "${GREEN}> [Usuń nieużywane]${NC}" || echo "  [Usuń nieużywane]"
        [ $sel -eq 2 ] && echo -e "${GREEN}> [Lista pakietów]${NC}" || echo "  [Lista pakietów]"
        [ $sel -eq 3 ] && echo -e "${GREEN}> [Wyszukaj]${NC}" || echo "  [Wyszukaj]"
        [ $sel -eq 4 ] && echo -e "${GREEN}> [Info o pakiecie]${NC}" || echo "  [Info o pakiecie]"
        [ $sel -eq 5 ] && echo -e "${GREEN}> [Naprawa systemu]${NC}" || echo "  [Naprawa systemu]"
        [ $sel -eq 6 ] && echo -e "${GREEN}> [Historia]${NC}" || echo "  [Historia]"
        [ $sel -eq 7 ] && echo -e "${GREEN}> [Export listy]${NC}" || echo "  [Export listy]"
        [ $sel -eq 8 ] && echo -e "${GREEN}> [Import listy]${NC}" || echo "  [Import listy]"
        [ $sel -eq 9 ] && echo -e "${GREEN}> [Sprawdź aktualizacje]${NC}" || echo "  [Sprawdź aktualizacje]"
        [ $sel -eq 10 ] && echo -e "${GREEN}> [Downgrade]${NC}" || echo "  [Downgrade]"
        [ $sel -eq 11 ] && echo -e "${GREEN}> [Blokada pakietu]${NC}" || echo "  [Blokada pakietu]"
        [ $sel -eq 12 ] && echo -e "${GREEN}> [Powrót]${NC}" || echo "  [Powrót]"
        echo ""; echo "↑↓, Enter"
        IFS= read -rsn1 key
        if [[ $key == $'\x1b' ]]; then read -rsn2 -t 0.1 key
            case "$key" in '[A') ((sel--)); [ $sel -lt 0 ] && sel=$max ;; '[B') ((sel++)); [ $sel -gt $max ] && sel=0 ;; esac
        elif [[ $key == "" ]]; then
            clear
            case $sel in
                0) echo "═══ CZYSZCZENIE CACHE ═══"; echo ""
                   case $PKG_MANAGER in
                       pacman) sudo pacman -Sc --noconfirm ;; apt) sudo apt clean && sudo apt autoclean ;;
                       dnf) sudo dnf clean all ;; yum) sudo yum clean all ;; zypper) sudo zypper clean ;;
                       emerge) sudo eclean distfiles ;; apk) sudo apk cache clean ;;
                       winget) info "Winget zarządza cache automatycznie" ;; esac
                   [ $? -eq 0 ] && success "Wyczyszczono!" || error $? "Błąd" ;;
                1) echo "═══ USUWANIE NIEUŻYWANYCH ═══"; echo ""
                   case $PKG_MANAGER in
                       pacman) orphans=$(pacman -Qtdq 2>/dev/null); [ -n "$orphans" ] && sudo pacman -Rns $orphans --noconfirm || info "Brak" ;;
                       apt) sudo apt autoremove -y ;; dnf) sudo dnf autoremove -y ;; yum) sudo yum autoremove -y ;;
                       zypper) sudo zypper packages --unneeded ;; emerge) sudo emerge --depclean ;;
                       apk|winget) info "Brak funkcji autoremove" ;; esac
                   [ $? -eq 0 ] && success "Usunięto!" || error $? "Błąd" ;;
                2) echo "═══ LISTA PAKIETÓW ═══"; echo ""
                   case $PKG_MANAGER in
                       pacman) pacman -Q | less ;; apt) dpkg --list | less ;; dnf) dnf list installed | less ;;
                       yum) yum list installed | less ;; zypper) zypper packages --installed-only | less ;;
                       emerge) qlist -I | less ;; apk) apk info | less ;; winget) winget list | less ;; esac ;;
                3) echo "═══ WYSZUKIWANIE ═══"; echo ""; read -p "Nazwa: " term
                   [ -n "$term" ] && case $PKG_MANAGER in
                       pacman) pacman -Ss "$term" | less ;; apt) apt search "$term" | less ;;
                       dnf) dnf search "$term" | less ;; yum) yum search "$term" | less ;;
                       zypper) zypper search "$term" | less ;; emerge) emerge --search "$term" | less ;;
                       apk) apk search "$term" | less ;; winget) winget search "$term" | less ;; esac ;;
                4) echo "═══ INFO O PAKIECIE ═══"; echo ""; read -p "Nazwa: " pkg
                   [ -n "$pkg" ] && case $PKG_MANAGER in
                       pacman) pacman -Si "$pkg" 2>/dev/null || pacman -Qi "$pkg" ;; apt) apt show "$pkg" ;;
                       dnf) dnf info "$pkg" ;; yum) yum info "$pkg" ;; zypper) zypper info "$pkg" ;;
                       emerge) emerge --info "$pkg" ;; apk) apk info "$pkg" ;; winget) winget show "$pkg" ;; esac ;;
                5) echo "═══ NAPRAWA SYSTEMU ═══"; echo ""
                   case $PKG_MANAGER in
                       pacman) sudo rm -rf /etc/pacman.d/gnupg; sudo pacman-key --init; sudo pacman-key --populate archlinux ;;
                       apt) sudo apt --fix-broken install -y; sudo dpkg --configure -a ;;
                       dnf) sudo dnf distro-sync ;; yum) sudo yum distro-sync ;; zypper) sudo zypper verify ;;
                       emerge) sudo emerge --update --deep --newuse @world ;; apk) sudo apk fix ;;
                       winget) winget source reset --force ;; esac
                   [ $? -eq 0 ] && success "Naprawiono!" || error $? "Błąd" ;;
                6) echo "═══ HISTORIA ═══"; echo ""
                   case $PKG_MANAGER in
                       pacman) sudo tail -n 50 /var/log/pacman.log | less ;;
                       apt) sudo tail -n 50 /var/log/apt/history.log | less ;;
                       dnf) dnf history | less ;; yum) yum history | less ;;
                       zypper) sudo tail -n 50 /var/log/zypp/history | less ;;
                       emerge) sudo tail -n 50 /var/log/emerge.log | less ;;
                       apk|winget) info "Brak historii" ;; esac ;;
                7) echo "═══ EXPORT LISTY ═══"; echo ""
                   case $PKG_MANAGER in
                       pacman) pacman -Qqe > ~/pakiety.txt; success "Zapisano ~/pakiety.txt" ;;
                       apt) dpkg --get-selections > ~/pakiety.txt; success "Zapisano ~/pakiety.txt" ;;
                       dnf|yum) $PKG_MANAGER list installed > ~/pakiety.txt; success "Zapisano ~/pakiety.txt" ;;
                       zypper) zypper packages --installed-only > ~/pakiety.txt; success "Zapisano ~/pakiety.txt" ;;
                       winget) winget export -o ~/pakiety.json; success "Zapisano ~/pakiety.json" ;;
                       *) error 1 "Nie wspierane" ;; esac ;;
                8) echo "═══ IMPORT LISTY ═══"; echo ""; read -p "Plik: " filepath
                   [ -f "$filepath" ] && case $PKG_MANAGER in
                       pacman) sudo pacman -S --needed --noconfirm - < "$filepath"; success "Zaimportowano!" ;;
                       apt) sudo dpkg --set-selections < "$filepath"; sudo apt-get dselect-upgrade -y; success "Zaimportowano!" ;;
                       winget) winget import -i "$filepath"; success "Zaimportowano!" ;;
                       *) error 1 "Nie wspierane" ;; esac || error 1 "Plik nie istnieje!" ;;
                9) echo "═══ SPRAWDŹ AKTUALIZACJE ═══"; echo ""
                   case $PKG_MANAGER in
                       pacman) checkupdates ;; apt) apt list --upgradable ;; dnf) dnf check-update ;;
                       yum) yum check-update ;; zypper) zypper list-updates ;; emerge) emerge -uDNp @world ;;
                       apk) apk version ;; winget) winget upgrade ;; esac ;;
                10) echo "═══ DOWNGRADE ═══"; echo ""; read -p "Pakiet: " pkg
                    [ -n "$pkg" ] && case $PKG_MANAGER in
                        pacman) info "Cache:"; ls /var/cache/pacman/pkg/ | grep "^$pkg-"; echo ""; read -p "Plik: " f
                                [ -n "$f" ] && sudo pacman -U "/var/cache/pacman/pkg/$f" --noconfirm ;;
                        apt) apt-cache policy "$pkg"; echo ""; read -p "Wersja: " v
                             [ -n "$v" ] && sudo apt install "$pkg=$v" -y ;;
                        winget) read -p "Wersja: " v; [ -n "$v" ] && winget install "$pkg" --version "$v" ;;
                        *) error 1 "Nie wspierane" ;; esac ;;
                11) echo "═══ BLOKADA PAKIETU ═══"; echo ""; read -p "Pakiet: " pkg
                    [ -z "$pkg" ] && { error 1 "Brak pakietu"; continue; }; echo ""; echo "1. Zablokuj"; echo "2. Odblokuj"; read -p "Wybór: " ch
                    case $ch in
                        1) case $PKG_MANAGER in
                               pacman) echo "IgnorePkg = $pkg" | sudo tee -a /etc/pacman.conf; success "Zablokowano" ;;
                               apt) sudo apt-mark hold "$pkg"; success "Zablokowano" ;;
                               dnf|yum) sudo $PKG_MANAGER versionlock add "$pkg"; success "Zablokowano" ;;
                               winget) winget pin add "$pkg"; success "Zablokowano" ;;
                               *) error 1 "Nie wspierane" ;; esac ;;
                        2) case $PKG_MANAGER in
                               pacman) sudo sed -i "/IgnorePkg.*$pkg/d" /etc/pacman.conf; success "Odblokowano" ;;
                               apt) sudo apt-mark unhold "$pkg"; success "Odblokowano" ;;
                               dnf|yum) sudo $PKG_MANAGER versionlock delete "$pkg"; success "Odblokowano" ;;
                               winget) winget pin remove "$pkg"; success "Odblokowano" ;;
                               *) error 1 "Nie wspierane" ;; esac ;;
                    esac ;;
                12) return ;;
            esac
            [ $sel -ne 12 ] && [ $sel -ne 2 ] && [ $sel -ne 3 ] && [ $sel -ne 4 ] && [ $sel -ne 6 ] && [ $sel -ne 9 ] && { echo ""; read -p "Enter..."; }
        fi
    done
}

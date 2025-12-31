#!/bin/bash

# ------------------ Kolory ------------------
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

# ------------------ Progress Bar ------------------
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

# ------------------ Dependencies ------------------
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

# ------------------ Draw Scrollable List ------------------
draw_list() {
    local list_var=$1
    local selected_var=$2
    local offset_var=$3
    local height_var=$4
    local last_sel_var=$5

    local -n list="$list_var"
    local -n selected="$selected_var"
    local -n offset="$offset_var"
    local -n height="$height_var"
    local last_sel="${!last_sel_var}"

    local total=${#list[@]}
    local end=$((offset+height))
    (( end>total )) && end=$total

    if [[ -z "$last_sel" ]]; then
        clear
        (( total>height )) && printf "%45s\n" "/\\"
        for ((i=offset;i<end;i++)); do
            if [[ $i -eq $selected ]]; then echo -e "${GREEN}> ${list[$i]}${NC}"; else echo "  ${list[$i]}"; fi
        done
        (( total>height )) && printf "%45s\n" "\\/"
        eval "$last_sel_var=$selected"
        return
    fi

    if [[ $selected -ne $last_sel ]]; then
        tput cup $((1+last_sel-offset)) 0
        echo "  ${list[$last_sel]}"
        tput cup $((1+selected-offset)) 0
        echo -e "${GREEN}> ${list[$selected]}${NC}"
        eval "$last_sel_var=$selected"
    fi
}

# ------------------ Package Manager ------------------
select_package_manager() {
    local options=("pacman (Arch)" "apt (Debian/Ubuntu)" "dnf (Fedora)" "yum (CentOS/RHEL)" "zypper (openSUSE)" "emerge (Gentoo)" "apk (Alpine)" "Autowykryj")
    local selected=0 offset=0 last_sel=""
    local height=$(tput lines)
    ((height-=6))

    while true; do
        draw_list options selected offset height last_sel
        IFS= read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            IFS= read -rsn1 -t 0.01 key2
            if [[ $key2 == '[' ]]; then
                IFS= read -rsn1 -t 0.01 key3
                if [[ $key3 == 'A' ]]; then ((selected--)); [ $selected -lt 0 ] && selected=$((${#options[@]}-1))
                elif [[ $key3 == 'B' ]]; then ((selected++)); [ $selected -ge ${#options[@]} ] && selected=0
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

autodetect_package_manager() {
    if command -v pacman &> /dev/null; then PKG_MANAGER="pacman"; PKG_MANAGER_NAME="Pacman (Arch)"
    elif command -v apt &> /dev/null; then PKG_MANAGER="apt"; PKG_MANAGER_NAME="APT (Debian/Ubuntu)"
    elif command -v dnf &> /dev/null; then PKG_MANAGER="dnf"; PKG_MANAGER_NAME="DNF (Fedora)"
    elif command -v yum &> /dev/null; then PKG_MANAGER="yum"; PKG_MANAGER_NAME="YUM (CentOS/RHEL)"
    elif command -v zypper &> /dev/null; then PKG_MANAGER="zypper"; PKG_MANAGER_NAME="Zypper (openSUSE)"
    elif command -v emerge &> /dev/null; then PKG_MANAGER="emerge"; PKG_MANAGER_NAME="Emerge (Gentoo)"
    elif command -v apk &> /dev/null; then PKG_MANAGER="apk"; PKG_MANAGER_NAME="APK (Alpine)"
    else clear; error 1 "Nie wykryto menedżera pakietów!"; exit 1; fi
    clear; success "Wykryto: $PKG_MANAGER_NAME"; sleep 1
}

# ------------------ Menu ------------------
show_menu() {
    local selected=$1
    clear
    echo "╔════════════════════════════════════╗"
    echo "║     MENEDŻER PAKIETÓW              ║"
    echo "╚════════════════════════════════════╝"
    echo ""
    info "Używasz: $PKG_MANAGER_NAME"
    echo ""
    local options=("Install" "Uninstall" "Update" "Custom" "Install DE" "Pomocne komendy" "Zmień menedżer" "Exit")
    for i in "${!options[@]}"; do
        if [[ $i -eq $selected ]]; then
            echo -e "${GREEN}> [${options[$i]}]${NC}"
        else
            echo "  [${options[$i]}]"
        fi
    done
    echo ""
    echo "Strzałki ↑↓, Enter"
}

# ------------------ Install ------------------
install_package() {
    clear
    echo "╔════════════════════════════════════╗"
    echo "║         INSTALACJA PAKIETU         ║"
    echo "╚════════════════════════════════════╝"
    echo ""
    read -p "Nazwa: " package
    [ -z "$package" ] && { error 1 "Brak nazwy"; return; }
    info "Instaluję: $package"
    case $PKG_MANAGER in
        pacman) sudo pacman -S "$package" --noconfirm ;;
        apt) sudo apt install -y "$package" ;;
        dnf) sudo dnf install -y "$package" ;;
        yum) sudo yum remove -y "$package" ;;
        zypper) sudo zypper install -y "$package" ;;
        emerge) sudo emerge "$package" ;;
        apk) sudo apk add "$package" ;;
    esac
    [ $? -eq 0 ] && success "Zainstalowano" || error $? "Błąd"
    read -p "Enter..."
}

# ------------------ Uninstall ------------------
uninstall_package() {
    clear
    echo "╔════════════════════════════════════╗"
    echo "║        DEINSTALACJA PAKIETU        ║"
    echo "╚════════════════════════════════════╝"
    echo ""
    read -p "Nazwa: " package
    [ -z "$package" ] && { error 1 "Brak nazwy"; return; }
    info "Usuwam: $package"
    case $PKG_MANAGER in
        pacman) sudo pacman -R "$package" --noconfirm ;;
        apt) sudo apt remove -y "$package" ;;
        dnf) sudo dnf remove -y "$package" ;;
        yum) sudo yum remove -y "$package" ;;
        zypper) sudo zypper remove -y "$package" ;;
        emerge) sudo emerge --deselect "$package" ;;
        apk) sudo apk del "$package" ;;
    esac
    [ $? -eq 0 ] && success "Usunięto" || error $? "Błąd"
    read -p "Enter..."
}

# ------------------ Update System ------------------
update_system() {
    info "Aktualizacja całego systemu..."
    case $PKG_MANAGER in
        pacman) sudo pacman -Syu --noconfirm ;;
        apt) sudo apt update && sudo apt upgrade -y ;;
        dnf) sudo dnf upgrade -y ;;
        yum) sudo yum update -y ;;
        zypper) sudo zypper update -y ;;
        emerge) sudo emerge --update --deep --newuse @world ;;
        apk) sudo apk upgrade ;;
    esac
    [ $? -eq 0 ] && success "Zaktualizowano!" || error $? "Błąd"
    read -p "Enter..."
}

# ------------------ Custom Command ------------------
custom_command() {
    read -p "Komenda: " command
    [ -z "$command" ] && { error 1 "Brak komendy"; return; }
    info "Wykonuję: $command"
    eval "$command"
    [ $? -eq 0 ] && success "Wykonano" || error $? "Błąd"
    read -p "Enter..."
}

# ------------------ DE Installation ------------------
install_de() {
    info "Instalacja środowiska desktop..."
    read -p "DE (kde/gnome/xfce): " de
    case $de in
        kde) sudo pacman -S --noconfirm plasma kde-applications sddm; sudo systemctl enable sddm ;;
        gnome) sudo pacman -S --noconfirm gnome gnome-extra gdm; sudo systemctl enable gdm ;;
        xfce) sudo pacman -S --noconfirm xfce4 xfce4-goodies lightdm; sudo systemctl enable lightdm ;;
        *) error 1 "Nieznane DE" ;;
    esac
    [ $? -eq 0 ] && success "Zainstalowano DE" || error $? "Błąd"
    read -p "Enter..."
}

# ------------------ Helpful Commands ------------------
helpful_commands() {
    local options=("Wyczyść cache" "Usuń nieużywane" "Lista pakietów" "Wyszukaj pakiet" "Info o pakiecie" "Naprawa systemu" "Historia" "Export listy" "Import listy" "Sprawdź aktualizacje" "Downgrade" "Blokada pakietu" "Powrót")
    local selected=0 offset=0 last_sel=""
    local height=$(tput lines)
    ((height-=6))

    while true; do
        draw_list options selected offset height last_sel
        IFS= read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            IFS= read -rsn1 -t 0.01 key2
            if [[ $key2 == '[' ]]; then
                IFS= read -rsn1 -t 0.01 key3
                if [[ $key3 == 'A' ]]; then ((selected--)); [ $selected -lt 0 ] && selected=$((${#options[@]}-1))
                elif [[ $key3 == 'B' ]]; then ((selected++)); [ $selected -ge ${#options[@]} ] && selected=0
                fi
            fi
        elif [[ $key == "" ]]; then
            case $selected in
                0) case $PKG_MANAGER in pacman) sudo pacman -Sc --noconfirm ;; apt) sudo apt clean && sudo apt autoclean ;; esac ;;
                1) case $PKG_MANAGER in pacman) sudo pacman -Rns $(pacman -Qtdq) --noconfirm ;; apt) sudo apt autoremove -y ;; esac ;;
                2) case $PKG_MANAGER in pacman) pacman -Q | less ;; apt) dpkg --list | less ;; esac ;;
                3) read -p "Nazwa: " term; [[ $PKG_MANAGER == "pacman" ]] && pacman -Ss "$term" | less ;; 
                4) read -p "Pakiet: " pkg; [[ $PKG_MANAGER == "pacman" ]] && pacman -Si "$pkg" 2>/dev/null || pacman -Qi "$pkg" ;;
                12) return ;;
            esac
        fi
    done
}

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
        echo ""; echo "↑↓ lub dotknij, Enter"
        IFS= read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            IFS= read -rsn1 -t 0.01 key2
            if [[ $key2 == '[' ]]; then
                IFS= read -rsn1 -t 0.01 key3
                if [[ $key3 == 'A' ]]; then ((sel--)); [ $sel -lt 0 ] && sel=$max
                elif [[ $key3 == 'B' ]]; then ((sel++)); [ $sel -gt $max ] && sel=0
                elif [[ $key3 == '<' ]]; then
                    local mouse_seq=""
                    while IFS= read -rsn1 -t 0.01 char; do 
                        mouse_seq+="$char"
                        [[ $char == 'M' || $char == 'm' ]] && break
                    done
                    if [[ "$mouse_seq" =~ ^([0-9]+)\;([0-9]+)\;([0-9]+)M ]]; then
                        local y="${BASH_REMATCH[3]}"
                        local clicked=$((y - 5))
                        if [ $clicked -ge 0 ] && [ $clicked -le $max ]; then
                            sel=$clicked
                            key=""
                        fi
                    fi
                fi
            fi
        fi
        
        if [[ $key == "" ]]; then
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
}bar_width -gt 60 ] && bar_width=60
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
    [ -n "$message" ] && { echo ""; local msg_padding=$(( (term_width - ${#message}) / 2 )); printf "%*s" $msg

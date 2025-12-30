#!/bin/bash

# Kolory
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="$HOME/.local/bin/ui-manager"
SYMLINK_PATH="/usr/local/bin/ui-manager"

success() { echo -e "${GREEN}[✔]${NC} $*"; }
error() { echo -e "${RED}[✖]${NC} $*"; }
info() { echo -e "${BLUE}[ℹ]${NC} $*"; }
warning() { echo -e "${YELLOW}[⚠]${NC} $*"; }

show_menu() {
    local selected=$1
    clear
    echo -e "${BLUE}╔════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     UI PACKAGE MANAGER INSTALLER   ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════╝${NC}"
    echo ""
    
    [ $selected -eq 0 ] && echo -e "${GREEN}> [Install]${NC}" || echo "  [Install]"
    [ $selected -eq 1 ] && echo -e "${GREEN}> [Uninstall]${NC}" || echo "  [Uninstall]"
    [ $selected -eq 2 ] && echo -e "${GREEN}> [Update]${NC}" || echo "  [Update]"
    [ $selected -eq 3 ] && echo -e "${GREEN}> [Exit]${NC}" || echo "  [Exit]"
    
    echo ""
    echo "Użyj strzałek ↑↓, Enter"
}

check_git() {
    if ! command -v git &> /dev/null; then
        echo ""
        warning "Git nie jest zainstalowany!"
        echo ""
        info "Instaluję git..."
        
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y git
        elif command -v pacman &> /dev/null; then
            sudo pacman -Sy --noconfirm git
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y git
        elif command -v yum &> /dev/null; then
            sudo yum install -y git
        elif command -v pkg &> /dev/null; then
            pkg install -y git
        else
            error "Nie można zainstalować git automatycznie"
            echo "Zainstaluj git ręcznie: apt/pacman/dnf/yum install git"
            return 1
        fi
        
        if ! command -v git &> /dev/null; then
            error "Instalacja git nie powiodła się"
            return 1
        fi
        
        success "Git zainstalowany!"
    fi
    return 0
}

select_clone_method() {
    local selected=0
    local max_options=2
    
    while true; do
        clear
        echo -e "${BLUE}╔════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║     WYBIERZ METODĘ DOSTĘPU         ║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════╝${NC}"
        echo ""
        
        [ $selected -eq 0 ] && echo -e "${GREEN}> [HTTPS (Personal Access Token)]${NC}" || echo "  [HTTPS (Personal Access Token)]"
        [ $selected -eq 1 ] && echo -e "${GREEN}> [SSH Key]${NC}" || echo "  [SSH Key]"
        [ $selected -eq 2 ] && echo -e "${GREEN}> [HTTPS (publiczne repo)]${NC}" || echo "  [HTTPS (publiczne repo)]"
        
        echo ""
        echo "Strzałki ↑↓, Enter"
        
        IFS= read -rsn1 key
        
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 -t 0.1 key
            case "$key" in
                '[A') ((selected--)); [ $selected -lt 0 ] && selected=$max_options ;;
                '[B') ((selected++)); [ $selected -gt $max_options ] && selected=0 ;;
            esac
        elif [[ $key == "" ]]; then
            case $selected in
                0)
                    clear
                    echo -e "${BLUE}╔════════════════════════════════════╗${NC}"
                    echo -e "${BLUE}║     PERSONAL ACCESS TOKEN          ║${NC}"
                    echo -e "${BLUE}╚════════════════════════════════════╝${NC}"
                    echo ""
                    info "Instrukcje:"
                    echo "1. Idź na: https://github.com/settings/tokens"
                    echo "2. Generate new token (classic)"
                    echo "3. Zaznacz 'repo' scope"
                    echo "4. Skopiuj token"
                    echo ""
                    read -p "Wklej token (ghp_...): " token
                    
                    if [ -z "$token" ]; then
                        error "Nie podano tokena!"
                        sleep 2
                        continue
                    fi
                    
                    CLONE_URL="https://${token}@github.com/tosterqgg/Ui.git"
                    return 0
                    ;;
                1)
                    clear
                    echo -e "${BLUE}╔════════════════════════════════════╗${NC}"
                    echo -e "${BLUE}║          SSH KEY                   ║${NC}"
                    echo -e "${BLUE}╚════════════════════════════════════╝${NC}"
                    echo ""
                    info "Sprawdzam klucz SSH..."
                    
                    if [ ! -f "$HOME/.ssh/id_ed25519" ] && [ ! -f "$HOME/.ssh/id_rsa" ]; then
                        warning "Brak klucza SSH!"
                        echo ""
                        info "Generuję nowy klucz..."
                        ssh-keygen -t ed25519 -C "ui-manager@github" -f "$HOME/.ssh/id_ed25519" -N ""
                        success "Klucz wygenerowany!"
                    fi
                    
                    echo ""
                    info "Twój publiczny klucz SSH:"
                    echo ""
                    if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
                        cat "$HOME/.ssh/id_ed25519.pub"
                    else
                        cat "$HOME/.ssh/id_rsa.pub"
                    fi
                    echo ""
                    echo ""
                    info "Dodaj ten klucz na GitHub:"
                    echo "https://github.com/settings/ssh/new"
                    echo ""
                    read -p "Naciśnij Enter gdy dodasz klucz..."
                    
                    CLONE_URL="git@github.com:tosterqgg/Ui.git"
                    return 0
                    ;;
                2)
                    CLONE_URL="https://github.com/tosterqgg/Ui.git"
                    return 0
                    ;;
            esac
        fi
    done
}

do_install() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║          INSTALACJA                ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════╝${NC}"
    echo ""
    
    check_git || { read -p "Enter..."; return 1; }
    
    # Wybierz metodę klonowania
    select_clone_method
    
    echo ""
    info "Pobieranie z repozytorium..."
    echo ""
    
    # Usuń stary katalog jeśli istnieje
    if [ -d "$INSTALL_DIR" ]; then
        warning "Katalog już istnieje, usuwam..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # Utwórz katalog nadrzędny
    mkdir -p "$(dirname "$INSTALL_DIR")"
    
    # Klonuj repozytorium
    if ! git clone "$CLONE_URL" "$INSTALL_DIR" 2>&1; then
        echo ""
        error "Błąd pobierania z repozytorium!"
        echo ""
        info "Możliwe przyczyny:"
        echo "  1. Nieprawidłowy token/klucz SSH"
        echo "  2. Brak połączenia z internetem"
        echo "  3. Repozytorium nie istnieje"
        read -p "Enter..."
        return 1
    fi
    
    echo ""
    success "Pobrano pomyślnie!"
    echo ""
    
    # Przejdź do katalogu
    cd "$INSTALL_DIR" || { error "Nie można wejść do katalogu!"; return 1; }
    
    # Nadaj uprawnienia wykonywania
    info "Nadawanie uprawnień..."
    chmod +x ui.sh 2>/dev/null
    chmod +x functions.sh 2>/dev/null
    
    # Sprawdź czy pliki istnieją
    if [ ! -f "ui.sh" ]; then
        error "Brak pliku ui.sh w repozytorium!"
        read -p "Enter..."
        return 1
    fi
    
    if [ ! -f "functions.sh" ]; then
        error "Brak pliku functions.sh w repozytorium!"
        read -p "Enter..."
        return 1
    fi
    
    # Utwórz wrapper script
    info "Tworzenie skryptu uruchamiającego..."
    cat > "$INSTALL_DIR/ui-manager" << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
exec ./ui.sh "$@"
EOF
    chmod +x "$INSTALL_DIR/ui-manager"
    
    # Utwórz symlink
    info "Tworzenie linku systemowego..."
    if [ -w "/usr/local/bin" ]; then
        ln -sf "$INSTALL_DIR/ui-manager" "$SYMLINK_PATH"
    else
        sudo ln -sf "$INSTALL_DIR/ui-manager" "$SYMLINK_PATH"
    fi
    
    if [ -L "$SYMLINK_PATH" ]; then
        success "Link utworzony: $SYMLINK_PATH"
    else
        warning "Nie udało się utworzyć linku (nie krytyczne)"
    fi
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║        INSTALACJA UKOŃCZONA!       ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════╝${NC}"
    echo ""
    info "Uruchom przez:"
    echo "  ${YELLOW}ui-manager${NC}"
    echo "  lub: ${YELLOW}$INSTALL_DIR/ui.sh${NC}"
    echo ""
    
    read -p "Uruchomić teraz? (y/n): " run_now
    if [[ "$run_now" =~ ^[Yy]$ ]]; then
        echo ""
        exec "$INSTALL_DIR/ui.sh"
    fi
}

do_uninstall() {
    clear
    echo -e "${RED}╔════════════════════════════════════╗${NC}"
    echo -e "${RED}║          DEINSTALACJA              ║${NC}"
    echo -e "${RED}╚════════════════════════════════════╝${NC}"
    echo ""
    
    if [ ! -d "$INSTALL_DIR" ]; then
        warning "UI Manager nie jest zainstalowany!"
        echo ""
        read -p "Enter..."
        return
    fi
    
    warning "To usunie UI Manager z systemu!"
    echo ""
    read -p "Kontynuować? (y/n): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        info "Anulowano"
        sleep 1
        return
    fi
    
    echo ""
    info "Usuwanie plików..."
    
    # Usuń katalog
    rm -rf "$INSTALL_DIR"
    
    # Usuń symlink
    if [ -L "$SYMLINK_PATH" ]; then
        if [ -w "/usr/local/bin" ]; then
            rm "$SYMLINK_PATH"
        else
            sudo rm "$SYMLINK_PATH"
        fi
    fi
    
    echo ""
    success "UI Manager został usunięty!"
    echo ""
    read -p "Enter..."
}

do_update() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║          AKTUALIZACJA              ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════╝${NC}"
    echo ""
    
    if [ ! -d "$INSTALL_DIR" ]; then
        warning "UI Manager nie jest zainstalowany!"
        echo ""
        info "Użyj opcji 'Install' aby zainstalować"
        read -p "Enter..."
        return
    fi
    
    info "Pobieranie aktualizacji..."
    echo ""
    
    cd "$INSTALL_DIR" || { error "Nie można wejść do katalogu!"; return 1; }
    
    # Pobierz aktualizacje
    if ! git pull 2>&1; then
        echo ""
        error "Błąd aktualizacji!"
        echo ""
        info "Spróbuj przeinstalować używając opcji Install"
        read -p "Enter..."
        return 1
    fi
    
    # Nadaj uprawnienia
    chmod +x ui.sh functions.sh ui-manager 2>/dev/null
    
    echo ""
    success "Zaktualizowano pomyślnie!"
    echo ""
    read -p "Enter..."
}

main() {
    local selected=0
    local max_options=3
    
    while true; do
        show_menu $selected
        IFS= read -rsn1 key
        
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 -t 0.1 key
            case "$key" in
                '[A') ((selected--)); [ $selected -lt 0 ] && selected=$max_options ;;
                '[B') ((selected++)); [ $selected -gt $max_options ] && selected=0 ;;
            esac
        elif [[ $key == "" ]]; then
            case $selected in
                0) do_install ;;
                1) do_uninstall ;;
                2) do_update ;;
                3) clear; echo "Do widzenia!"; exit 0 ;;
            esac
        fi
    done
}

main

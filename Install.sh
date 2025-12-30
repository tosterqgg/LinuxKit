#!/bin/bash

# Kolory
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     INSTALATOR UI PACKAGE MANAGER  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════╝${NC}"
echo ""

# Sprawdź czy git jest zainstalowany
if ! command -v git &> /dev/null; then
    echo -e "${RED}[✖]${NC} Git nie jest zainstalowany!"
    echo ""
    echo -e "${YELLOW}Instaluję git...${NC}"
    
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
        echo -e "${RED}[✖]${NC} Nie można zainstalować git automatycznie"
        echo "Zainstaluj git ręcznie i uruchom ponownie"
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        echo -e "${RED}[✖]${NC} Instalacja git nie powiodła się"
        exit 1
    fi
    
    echo -e "${GREEN}[✔]${NC} Git zainstalowany!"
    echo ""
fi

# Katalog instalacji
INSTALL_DIR="$HOME/.local/bin/ui-manager"

echo -e "${BLUE}[ℹ]${NC} Pobieranie z repozytorium..."
echo ""

# Usuń stary katalog jeśli istnieje
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}[⚠]${NC} Katalog już istnieje, usuwam stary..."
    rm -rf "$INSTALL_DIR"
fi

# Klonuj repozytorium
if git clone https://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@github.com/tosterqgg/Ui.git "$INSTALL_DIR" 2>&1 | grep -q "fatal\|error"; then
    echo -e "${RED}[✖]${NC} Błąd pobierania z repozytorium!"
    echo ""
    echo "Możliwe przyczyny:"
    echo "  1. Repozytorium jest prywatne - skonfiguruj dostęp SSH/token"
    echo "  2. Brak połączenia z internetem"
    echo "  3. Nieprawidłowy URL repozytorium"
    echo ""
    echo "Aby sklonować prywatne repozytorium:"
    echo "  git clone https://YOUR_TOKEN@github.com/tosterqgg/Ui.git"
    exit 1
fi

echo ""
echo -e "${GREEN}[✔]${NC} Pobrano pomyślnie!"
echo ""

# Przejdź do katalogu
cd "$INSTALL_DIR" || exit 1

# Nadaj uprawnienia wykonywania
echo -e "${BLUE}[ℹ]${NC} Nadawanie uprawnień..."
chmod +x ui.sh 2>/dev/null
chmod +x functions.sh 2>/dev/null

# Sprawdź czy pliki istnieją
if [ ! -f "ui.sh" ]; then
    echo -e "${RED}[✖]${NC} Błąd: Brak pliku ui.sh w repozytorium!"
    exit 1
fi

if [ ! -f "functions.sh" ]; then
    echo -e "${RED}[✖]${NC} Błąd: Brak pliku functions.sh w repozytorium!"
    exit 1
fi

# Utwórz symlink w /usr/local/bin (opcjonalnie)
echo ""
echo -e "${YELLOW}Czy chcesz utworzyć link w /usr/local/bin? (y/n)${NC}"
echo -e "${YELLOW}Dzięki temu będziesz mógł uruchomić przez: ui-manager${NC}"
read -p "> " create_link

if [[ "$create_link" =~ ^[Yy]$ ]]; then
    if [ -w "/usr/local/bin" ]; then
        ln -sf "$INSTALL_DIR/ui.sh" "/usr/local/bin/ui-manager"
        echo -e "${GREEN}[✔]${NC} Link utworzony: /usr/local/bin/ui-manager"
    else
        sudo ln -sf "$INSTALL_DIR/ui.sh" "/usr/local/bin/ui-manager"
        echo -e "${GREEN}[✔]${NC} Link utworzony: /usr/local/bin/ui-manager"
    fi
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        INSTALACJA UKOŃCZONA!       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Uruchom przez:${NC}"
echo -e "  ${YELLOW}$INSTALL_DIR/ui.sh${NC}"

if [[ "$create_link" =~ ^[Yy]$ ]]; then
    echo -e "  lub po prostu: ${YELLOW}ui-manager${NC}"
fi

echo ""
echo -e "${BLUE}Aby odinstalować:${NC}"
echo -e "  ${YELLOW}rm -rf $INSTALL_DIR${NC}"

if [[ "$create_link" =~ ^[Yy]$ ]]; then
    echo -e "  ${YELLOW}sudo rm /usr/local/bin/ui-manager${NC}"
fi

echo ""
echo -e "${GREEN}Uruchomić teraz? (y/n)${NC}"
read -p "> " run_now

if [[ "$run_now" =~ ^[Yy]$ ]]; then
    echo ""
    exec "$INSTALL_DIR/ui.sh"
zainstalowanyinstalowany

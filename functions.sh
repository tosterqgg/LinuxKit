#!/usr/bin/env bash

######################
# KOLORY
######################
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
NC=$'\033[0m'

######################
# GLOBALS
######################
PKG_MANAGER=""
PKG_MANAGER_NAME=""

######################
# HELPERY
######################
success(){ echo -e "${GREEN}[✔]${NC} $*"; }
error(){ echo -e "${RED}[✖]${NC} $*"; }
info(){ echo -e "${BLUE}[i]${NC} $*"; }

######################
# WYBÓR MANAGERA (1:1)
######################
select_package_manager() {
  local managers=("pacman" "apt" "dnf" "zypper" "apk")
  local selected=0

  while true; do
    clear
    echo "╔════════════════════════════════════════╗"
    echo "║ Wybierz manager                        ║"
    echo "╚════════════════════════════════════════╝"
    echo

    for i in "${!managers[@]}"; do
      if [[ $i -eq $selected ]]; then
        echo -e "${GREEN}>${NC} ${managers[$i]}"
      else
        echo "  ${managers[$i]}"
      fi
    done

    read -rsn1 key
    case "$key" in
      $'\x1b')
        read -rsn2 k
        [[ $k == "[A" ]] && ((selected--))
        [[ $k == "[B" ]] && ((selected++))
        ;;
      "")
        PKG_MANAGER="${managers[$selected]}"
        PKG_MANAGER_NAME="${managers[$selected]}"
        return
        ;;
      q) exit 0 ;;
    esac

    (( selected < 0 )) && selected=$((${#managers[@]}-1))
    (( selected >= ${#managers[@]} )) && selected=0
  done
}

######################
# MENU GŁÓWNE
######################
show_menu() {
  local items=("Install" "Uninstall" "Update" "Custom" "Exit")
  local selected=0

  while true; do
    clear
    echo "╔════════════════════════════════════════╗"
    echo "║ MENEDŻER PAKIETÓW                      ║

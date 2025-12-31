#!/usr/bin/env bash

############################################
# KOLORY (DOKŁADNIE JAK PIERWOTNIE)
############################################
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
NC=$'\033[0m'

############################################
# GLOBALS
############################################
PKG_MANAGER=""
PKG_MANAGER_NAME=""

############################################
# MOUSE / TOUCH
############################################
enable_mouse(){ printf '\033[?1000h\033[?1002h\033[?1006h'; }
disable_mouse(){ printf '\033[?1000l\033[?1002l\033[?1006l'; }

############################################
# SCROLL LIST (WYGLĄD JAK 1. WERSJA)
############################################
draw_scroll_list() {
  local -n ITEMS=$1
  local selected=$2
  local offset=$3
  local height=$4

  local total=${#ITEMS[@]}
  local end=$((offset+height))
  (( end > total )) && end=$total

  local show_scrollbar=0
  (( total > height )) && show_scrollbar=1

  (( show_scrollbar )) && printf "%58s\n" "/\\"

  for ((i=offset;i<end;i++)); do
    if [[ $i -eq $selected ]]; then
      printf "%b\n" "${GREEN}>${NC} ${ITEMS[$i]}"
    else
      printf "  %s\n" "${ITEMS[$i]}"
    fi
  done

  (( show_scrollbar )) && printf "%58s\n" "\\/"
}

############################################
# GENERIC MENU (BEZ ZMIAN WYGLĄDU)
############################################
scroll_menu() {
  local -n LIST=$1
  local title="$2"

  local selected=0 offset=0
  local height=$(( $(tput lines) - 8 ))
  (( height < 5 )) && height=5
  local max=$(( ${#LIST[@]}-1 ))

  enable_mouse
  while true; do
    clear
    echo "╔════════════════════════════════════════╗"
    printf "║ %-38s ║\n" "$title"
    echo "╚════════════════════════════════════════╝"

    draw_scroll_list LIST $selected $offset $height

    IFS= read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
      read -rsn2 -t 0.01 k2
      [[ $k2 == "[A" ]] && ((selected--))
      [[ $k2 == "[B" ]] && ((selected++))
      [[ $k2 == "[<" ]] && {
        local seq="<"
        while read -rsn1 -t 0.01 c; do seq+="$c"; [[ $c == "M" || $c == "m" ]] && break; done
        [[ $seq =~ \<([0-9]+)\;([0-9]+)\;([0-9]+) ]] && {
          local y=${BASH_REMATCH[3]}
          local idx=$((offset + y - 5))
          (( idx>=0 && idx<=max )) && selected=$idx
        }
      }
    elif [[ $key == "" ]]; then
      disable_mouse
      return $selected
    elif [[ $key == "q" ]]; then
      disable_mouse
      return 255
    fi

    (( selected<0 )) && selected=$max
    (( selected>max )) && selected=0
    (( selected<offset )) && offset=$selected
    (( selected>=offset+height )) && offset=$((selected-height+1))
  done
}

############################################
# PACKAGE MANAGER (NAPRAWIONE KOLORY)
############################################
select_pkg_manager() {
  local managers=("pacman" "apt" "dnf" "zypper" "apk")
  scroll_menu managers "Wybierz manager"
  local r=$?
  [[ $r == 255 ]] && exit 0
  PKG_MANAGER="${managers[$r]}"
  PKG_MANAGER_NAME="${managers[$r]}"
}

############################################
# ACTIONS
############################################
install_package(){ read -rp "Pakiet: " p; sudo $PKG_MANAGER install "$p"; read -n1; }
uninstall_package(){ read -rp "Pakiet: " p; sudo $PKG_MANAGER remove "$p"; read -n1; }
update_system(){ sudo $PKG_MANAGER update && sudo $PKG_MANAGER upgrade; read -n1; }
custom_command(){ read -rp "Komenda: " c; eval "$c"; read -n1; }

############################################
# HELPERS
############################################
helpful_commands() {
  local cmds=("htop" "neofetch" "lsblk" "df -h" "ip a")
  scroll_menu cmds "Pomocne komendy"
  local r=$?
  [[ $r != 255 ]] && eval "${cmds[$r]}"
  read -n1
}

############################################
# MAIN MENU
############################################
main_menu() {
  local menu=("Install" "Uninstall" "Update" "Custom command" "Helpful commands" "Change manager" "Exit")
  while true; do
    scroll_menu menu "Menu ($PKG_MANAGER_NAME)"
    case $? in

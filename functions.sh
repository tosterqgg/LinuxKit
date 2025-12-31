#!/usr/bin/env bash

############################################
# KOLORY
############################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

############################################
# GLOBALS
############################################
PKG_MANAGER=""
PKG_MANAGER_NAME=""

############################################
# UTILS
############################################
success(){ echo -e "${GREEN}[✔]${NC} $*"; }
info(){ echo -e "${BLUE}[i]${NC} $*"; }
fail(){ echo -e "${RED}[X]${NC} $*"; read -n1; }

############################################
# MOUSE / TOUCH ENABLE
############################################
enable_mouse() {
  printf '\033[?1000h\033[?1002h\033[?1006h'
}
disable_mouse() {
  printf '\033[?1000l\033[?1002l\033[?1006l'
}

############################################
# SCROLL LIST WITH RIGHT SCROLLBAR
############################################
draw_scroll_list() {
  local -n ITEMS=$1
  local selected=$2
  local offset=$3
  local height=$4

  local total=${#ITEMS[@]}
  local end=$((offset+height))
  (( end > total )) && end=$total

  echo "--------------------------------------------------------------"
  printf "%58s\n" "/\\"

  for ((i=offset;i<end;i++)); do
    local prefix="  "
    [[ $i -eq $selected ]] && prefix="${GREEN}>${NC} "
    printf "%s%-52s" "$prefix" "${ITEMS[$i]}"

    if (( total > height )); then
      local pos=$(( (i-offset)*height/total ))
      if (( i == offset+pos )); then
        echo -e "${YELLOW}█${NC}"
      else
        echo "│"
      fi
    else
      echo
    fi
  done

  printf "%58s\n" "\\/"
  echo "--------------------------------------------------------------"
}

############################################
# GENERIC SCROLL MENU (KEYBOARD + TOUCH)
############################################
scroll_menu() {
  local -n LIST=$1
  local title="$2"

  local selected=0 offset=0
  local height=10
  local max=$(( ${#LIST[@]}-1 ))

  enable_mouse
  while true; do
    clear
    echo "╔════════════════════════════════════════╗"
    printf "║ %-38s ║\n" "$title"
    echo "╚════════════════════════════════════════╝"
    draw_scroll_list LIST $selected $offset $height
    echo "↑↓ / klik / Enter / q"

    IFS= read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
      read -rsn2 -t 0.01 key2
      [[ $key2 == "[A" ]] && ((selected--))
      [[ $key2 == "[B" ]] && ((selected++))
      [[ $key2 == "[<" ]] && {
        local seq="<"
        while read -rsn1 -t 0.01 c; do seq+="$c"; [[ $c == "M" || $c == "m" ]] && break; done
        [[ $seq =~ \<([0-9]+)\;([0-9]+)\;([0-9]+) ]] && {
          local y=${BASH_REMATCH[3]}
          local idx=$((offset + y - 6))
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
# PACKAGE MANAGER SELECT
############################################
select_pkg_manager() {
  local managers=("pacman (Arch)" "apt (Debian/Ubuntu)" "dnf (Fedora)" "zypper (openSUSE)" "apk (Alpine)")
  scroll_menu managers "Wybierz manager"
  local r=$?
  [[ $r == 255 ]] && exit 0

  case $r in
    0) PKG_MANAGER="pacman";;
    1) PKG_MANAGER="apt";;
    2) PKG_MANAGER="dnf";;
    3) PKG_MANAGER="zypper";;
    4) PKG_MANAGER="apk";;
  esac
  PKG_MANAGER_NAME="${managers[$r]}"
}

############################################
# ACTIONS
############################################
install_package() {
  read -rp "Pakiet: " p
  sudo $PKG_MANAGER install $p || fail "Błąd instalacji"
}
uninstall_package() {
  read -rp "Pakiet: " p
  sudo $PKG_MANAGER remove $p || fail "Błąd usuwania"
}
update_system() {
  sudo $PKG_MANAGER update && sudo $PKG_MANAGER upgrade || fail "Błąd update"
}
custom_command() {
  read -rp "Komenda: " c
  eval "$c"
  read -n1
}

install_de() {
  local des=("GNOME" "KDE Plasma" "XFCE" "LXQt" "Cinnamon")
  scroll_menu des "Desktop Environment"
  local r=$?
  [[ $r == 255 ]] && return
  info "Wybrano ${des[$r]}"
  read -n1
}

helpful_commands() {
  local cmds=("htop" "neofetch" "lsblk" "df -h" "ip a")
  scroll_menu cmds "Pomocne komendy"
  local r=$?
  [[ $r == 255 ]] && return
  eval "${cmds[$r]}"
  read -n1
}

############################################
# MAIN MENU
############################################
main_menu() {
  local items=("Install" "Uninstall" "Update" "Custom command" "Install DE" "Helpful commands" "Change manager" "Exit")
  while true; do
    scroll_menu items "Menu główne ($PKG_MANAGER_NAME)"
    case $? in
      0) install_package;;
      1) uninstall_package;;
      2) update_system;;
      3) custom_command;;
      4) install_de;;
      5) helpful_commands;;
      6) select_pkg_manager;;
      7|255) exit 0;;
    esac
  done
}

############################################
# START
############################################
select_pkg_manager
main_menu

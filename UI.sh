#!/bin/bash

# Sprawdź czy functions.sh istnieje
if [ ! -f "$(dirname "$0")/functions.sh" ]; then
    echo "Błąd: Brak pliku functions.sh w tym samym katalogu!"
    echo "Pobierz oba pliki: menu.sh i functions.sh"
    exit 1
fi

# Załaduj funkcje
source "$(dirname "$0")/functions.sh"

# Uruchom sprawdzanie zależności
! command -v tput &> /dev/null && check_dependencies

# Główna pętla
main() {
    local selected=0 max_options=7 old_stty=$(stty -g)
    printf '\033[?1000h\033[?1002h\033[?1006h'
    
    while true; do
        show_menu $selected
        IFS= read -rsn1 key
        
        if [[ $key == $'\x1b' ]]; then
            IFS= read -rsn1 -t 0.01 key2
            if [[ $key2 == '[' ]]; then
                IFS= read -rsn1 -t 0.01 key3
                if [[ $key3 == 'A' ]]; then
                    ((selected--))
                    [ $selected -lt 0 ] && selected=$max_options
                elif [[ $key3 == 'B' ]]; then
                    ((selected++))
                    [ $selected -gt $max_options ] && selected=0
                elif [[ $key3 == '<' ]]; then
                    local mouse_seq="<"
                    while IFS= read -rsn1 -t 0.01 char; do
                        mouse_seq+="$char"
                        [[ $char == 'M' || $char == 'm' ]] && break
                    done
                    
                    if [[ "$mouse_seq" =~ \<([0-9]+)\;([0-9]+)\;([0-9]+)M ]]; then
                        local button="${BASH_REMATCH[1]}"
                        local x="${BASH_REMATCH[2]}"
                        local y="${BASH_REMATCH[3]}"
                        local clicked=$((y - 7))
                        
                        if [ $clicked -ge 0 ] && [ $clicked -le $max_options ]; then
                            selected=$clicked
                            case $selected in
                                0) install_package ;;
                                1) uninstall_package ;;
                                2) update_system ;;
                                3) custom_command ;;
                                4) install_de ;;
                                5) helpful_commands ;;
                                6) select_package_manager ;;
                                7)
                                    clear
                                    printf '\033[?1000l\033[?1002l\033[?1006l'
                                    info "Do widzenia!"
                                    stty "$old_stty"
                                    exit 0
                                    ;;
                            esac
                        fi
                    fi
                fi
            fi
        elif [[ $key == "" ]]; then
            case $selected in
                0) install_package ;;
                1) uninstall_package ;;
                2) update_system ;;
                3) custom_command ;;
                4) install_de ;;
                5) helpful_commands ;;
                6) select_package_manager ;;
                7)
                    clear
                    printf '\033[?1000l\033[?1002l\033[?1006l'
                    info "Do widzenia!"
                    stty "$old_stty"
                    exit 0
                    ;;
            esac
        fi
    done
}

# Start
select_package_manager
main

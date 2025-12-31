#!/bin/bash

# Sprawdź czy functions.sh istnieje
if [ ! -f "$(dirname "$0")/functions.sh" ]; then
    echo "Błąd: Brak pliku functions.sh w tym samym katalogu!"
    echo "Uruchom install.sh aby pobrać wszystkie pliki"
    exit 1
fi

# Załaduj funkcje
source "$(dirname "$0")/functions.sh"

# Sprawdź zależności
command -v tput &> /dev/null || check_dependencies

# ------------------ Główna pętla menu ------------------
main() {
    local selected=0
    local max_options=7
    local old_stty=$(stty -g)

    # Włącz tryb myszy
    printf '\033[?1000h\033[?1002h\033[?1006h'

    while true; do
        show_menu $selected
        IFS= read -rsn1 key

        if [[ $key == $'\x1b' ]]; then
            # Obsługa klawiszy specjalnych i myszy
            IFS= read -rsn1 -t 0.01 key2
            if [[ $key2 == '[' ]]; then
                IFS= read -rsn1 -t 0.01 key3
                case "$key3" in
                    A) ((selected--)); [ $selected -lt 0 ] && selected=$max_options ;;
                    B) ((selected++)); [ $selected -gt $max_options ] && selected=0 ;;
                    '<')
                        # Obsługa myszy
                        local mouse_seq="<"
                        while IFS= read -rsn1 -t 0.01 char; do
                            mouse_seq+="$char"
                            [[ $char == 'M' || $char == 'm' ]] && break
                        done
                        if [[ "$mouse_seq" =~ \<([0-9]+)\;([0-9]+)\;([0-9]+)M ]]; then
                            local clicked=$((BASH_REMATCH[2]-7))
                            if [ $clicked -ge 0 ] && [ $clicked -le $max_options ]; then
                                selected=$clicked
                                handle_selection $selected old_stty
                            fi
                        fi
                        ;;
                esac
            fi
        elif [[ $key == "" ]]; then
            handle_selection $selected old_stty
        fi
    done
}

# ------------------ Obsługa wyboru ------------------
handle_selection() {
    local sel=$1
    local old_stty=$2
    case $sel in
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
}

# ------------------ Start ------------------
# Wybór menedżera pakietów przed wejściem do menu
select_package_manager
main

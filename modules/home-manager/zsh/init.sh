CLR_LINES_UP=15
CLR_COLUMN=80
CLR_WIDTH=120
CLR_GREEN=$'\e[0;32m'
CLR_RESET=$'\e[0m'

hideTTY() {
    if [[ -t 0 ]]; then
        printf "\e[?25l"
    fi
}

restoreTTY() {
    restoreEcho() {
        if [[ -t 0 ]]; then
            stty echo 2>/dev/null
        fi
        autoload -Uz add-zle-hook-widget
        add-zle-hook-widget -d line-init restoreEcho
    }

    restoreCursor() {
        printf "\e[?25h"
        autoload -Uz add-zsh-hook
        add-zsh-hook -d precmd restoreCursor
    }

    autoload -Uz add-zle-hook-widget add-zsh-hook
    add-zle-hook-widget line-init restoreEcho
    add-zsh-hook precmd restoreCursor
}

setupCompletions() {
    autoload -Uz compinit
    local zcompdump="/Users/zhao/.config/zsh/.zcompdump"

    if [[ -f "$zcompdump" ]]; then
        compinit -C -d "$zcompdump"
    else
        compinit -d "$zcompdump"
    fi
}

setupKeybinds() {
    bindkey '^[[Z' autosuggest-accept
    bindkey '^k' up-line-or-history
    bindkey '^j' down-line-or-history
    bindkey '^h' backward-char
    bindkey '^l' forward-char
    bindkey '^x' delete-char
}

renderCalendar() {
    local cal_file="$HOME/.cache/fastfetch/myCalendar"
    if [[ -f "$cal_file" ]]; then
        printf "\e[%dA" "$CLR_LINES_UP"

        local lines_printed=0
        while IFS= read -r line; do
            printf "\e[%dG\e[K%s\n" "$CLR_COLUMN" "$line"
            ((lines_printed++))
        done < "$cal_file"

        local remaining=$(( CLR_LINES_UP - lines_printed ))
        if (( remaining > 0 )); then
            printf "\e[%dB" "$remaining"
        fi
    fi
}

redrawDashboard() {
    if [[ -f "$HOME/.cache/fastfetch/.first_prompt" ]]; then
        local DASHBOARD_LINES=18

        printf "\e[?25l"
        printf "\e7"
        printf "\e[%dA\e[1G" "$DASHBOARD_LINES"

        fastfetch

        if [[ -z "$VIFM_FLOAT" ]]; then
            renderCalendar
        fi

        printf "\e8"
        printf "\e[?25h"
    fi
}

updateCalendar() {
    local tmp_file="$HOME/.cache/fastfetch/myCalendar.tmp"
    local final_file="$HOME/.cache/fastfetch/myCalendar"

    {
        printf "${CLR_GREEN}Events${CLR_RESET} ➜\n"
        icalbuddy -f -n -nc -li 6 -ps "/ » /" -npn \
            -eep "url,location,notes,attendees" \
            -ec "Canadian Holidays,United States holidays,zhaoshen.zhai@gmail.com" \
            eventsFrom:now to:today+100 2>/dev/null | \
            awk -v l="$CLR_WIDTH" '{ if (length($0) > l) print substr($0, 1, l-3) "..."; else print $0 }'

        printf "\n"

        printf "${CLR_GREEN}Reminders${CLR_RESET} ➜\n"
        icalbuddy -li 6 uncompletedTasks | sed 's/ (Reminders)//g' 2>/dev/null | \
            awk -v l="$CLR_WIDTH" '{ if (length($0) > l) print substr($0, 1, l-3) "..."; else print $0 }'

        printf "${CLR_RESET}"
    } > "$tmp_file"

    mv "$tmp_file" "$final_file"
}

updateFetch() {
    fetchRaw() {
        fastfetch --config none --structure "$1" --logo none | sed 's/^[^:]*: //'
    }

    writeCache() {
        local target="$HOME/.cache/fastfetch/$1"
        awk '{printf "%s\033[K\n", $0}' > "$target.tmp"
        mv "$target.tmp" "$target"
    }

    local pkgs_raw
    pkgs_raw=$(fetchRaw "packages")
    echo "$pkgs_raw" | sed -E 's/nix-//g; s/, [0-9]+ \(brew[^)]*\)//g' | sed 's/default/user/g' | writeCache "myNix"
    echo "$pkgs_raw" | sed -E 's/.*, ([0-9]+ \(brew\)), ([0-9]+) \(brew-cask\)/\1, \2 (cask)/' | writeCache "myBrew"

    fetchRaw "os"       | writeCache "myOS"
    fetchRaw "host"     | writeCache "myHost"
    fetchRaw "cpu"      | writeCache "myCPU"
    fetchRaw "kernel"   | writeCache "myKernel"
    fetchRaw "uptime"   | writeCache "myUptime"
    fetchRaw "terminal" | writeCache "myTerminal"
    fetchRaw "shell"    | writeCache "myShell"
    fetchRaw "editor"   | writeCache "myEditor"

    fetchRaw "monitor"      | sed 's/ -.*//g'               | writeCache "myMonitor"
    fetchRaw "wm"           | grep -o 'AeroSpace [^)]*'     | writeCache "myWM"
    fetchRaw "terminalfont" | sed 's/Menlo/Courier Prime/g' | writeCache "myFont"
    fetchRaw "weather"      | sed 's/ (.*)//g'              | writeCache "myWeather"

    fetchRaw "media" | sed 's/ ([^)]*)$//' | awk -F ' - ' '{ a=$1; t=$2; if(length(a)>15) a=substr(a,1,12)"..."; if(length(t)>17) t=substr(t,1,14)"..."; if(NF>1) print a " - " t; else print substr($0,1,32)"..." }' | writeCache "myMedia"
}

updateAsync() {
    updateFetch
    updateCalendar
    kill -USR1 "$1" 2>/dev/null
}

main() {
    zle -N redrawDashboardWidget redrawDashboard

    TRAPUSR1() {
        if zle; then
            zle redrawDashboardWidget
        fi
    }

    hideTTY
    fastfetch

    if [[ -z "$VIFM_FLOAT" ]]; then
        renderCalendar
    fi

    setupCompletions
    setupKeybinds
    restoreTTY

    touch "$HOME/.cache/fastfetch/.first_prompt"

    autoload -Uz add-zsh-hook
    disableRedraw() {
        rm -f "$HOME/.cache/fastfetch/.first_prompt"
        add-zsh-hook -d preexec disableRedraw
    }
    add-zsh-hook preexec disableRedraw

    ( updateAsync $$ ) &!
}

main

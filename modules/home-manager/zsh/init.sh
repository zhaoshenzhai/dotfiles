export CLR_LINES_UP=15
export CLR_COLUMN=80
export CLR_WIDTH=120
export CLR_GREEN=$'\e[0;32m'
export CLR_RESET=$'\e[0m'

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

positionCalendar() {
    local cal_file="$HOME/.cache/fastfetch/myCalendar"
    if [[ -f "$cal_file" ]]; then
        printf "\e[s"
        printf "\e[${CLR_LINES_UP}A"

        while IFS= read -r line; do
            printf "\e[${CLR_COLUMN}G%s\n" "$line"
        done < "$cal_file"

        printf "\e[u"
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
    cacheFF() {
        local module=$1
        local target="$HOME/.cache/fastfetch/$2"
        fastfetch --config none --structure "$module" --logo none | sed 's/^[^:]*: //' > "$target.tmp"
        mv "$target.tmp" "$target"
    }

    cacheFF "monitor" "myMonitor"
    cacheFF "wm" "myWM"
    cacheFF "packages" "myPackages"
    cacheFF "terminal" "myTerminal"
    cacheFF "terminalfont" "myFont"
    cacheFF "shell" "myShell"
    cacheFF "editor" "myEditor"
    cacheFF "weather" "myWeather"
    cacheFF "media" "myMedia"
}

hideTTY
fastfetch
positionCalendar
setupCompletions
setupKeybinds
restoreTTY

(updateFetch; updateCalendar) &!

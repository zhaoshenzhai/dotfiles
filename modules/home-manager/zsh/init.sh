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

renderCalendar() {
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
    fetchRaw() {
        fastfetch --config none --structure "$1" --logo none | sed 's/^[^:]*: //'
    }

    writeCache() {
        local target="$HOME/.cache/fastfetch/$1"
        cat > "$target.tmp"
        mv "$target.tmp" "$target"
    }

    local pkgs_raw
    pkgs_raw=$(fetchRaw "packages")
    echo "$pkgs_raw" | sed -E 's/nix-//g; s/, [0-9]+ \(brew[^)]*\)//g' | sed 's/default/user/g' | writeCache "myNix"
    echo "$pkgs_raw" | sed -E 's/.*, ([0-9]+ \(brew\)), ([0-9]+) \(brew-cask\)/\1, \2 (cask)/' | writeCache "myBrew"

    fetchRaw "monitor" | sed 's/ -.*//g' | writeCache "myMonitor"
    fetchRaw "wm" | grep -o 'AeroSpace [^)]*' | writeCache "myWM"
    fetchRaw "terminal" | writeCache "myTerminal"
    fetchRaw "terminalfont" | sed 's/Menlo/Courier Prime/g' | writeCache "myFont"
    fetchRaw "shell" | writeCache "myShell"
    fetchRaw "editor" | writeCache "myEditor"
    fetchRaw "weather" | sed 's/ (.*)//g' | writeCache "myWeather"
    fetchRaw "media" | sed 's/ ([^)]*)$//' | awk -F ' - ' '{ a=$1; t=$2; if(length(a)>15) a=substr(a,1,12)"..."; if(length(t)>17) t=substr(t,1,14)"..."; if(NF>1) print a " - " t; else print substr($0,1,32)"..." }' | writeCache "myMedia"
}

hideTTY
fastfetch

if [[ -z "$VIFM_FLOAT" ]]; then
    renderCalendar
fi

setupCompletions
setupKeybinds
restoreTTY

(updateFetch; updateCalendar) &!

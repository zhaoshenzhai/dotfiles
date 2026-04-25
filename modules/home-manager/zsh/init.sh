export FF_LINES_UP=17
export FF_COLUMN=78
export FF_WIDTH=90
export CLR_GREEN=$'\e[0;32m'
export CLR_RESET=$'\e[0m'
export CLR_ULINE=$'\e[4m'
export CLR_NO_ULINE=$'\e[24m'

hideTTY() {
    if [[ -t 0 ]]; then
        stty -echo 2>/dev/null
    fi
}

restoreTTY() {
    autoload -Uz add-zle-hook-widget
    function _restore_tty_echo() {
        if [[ -t 0 ]]; then
            stty echo 2>/dev/null
        fi
        add-zle-hook-widget -d line-init _restore_tty_echo
    }
    add-zle-hook-widget line-init _restore_tty_echo
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
        printf "\e[${FF_LINES_UP}A"

        while IFS= read -r line; do
            printf "\e[${FF_COLUMN}G%s\n" "$line"
        done < "$cal_file"

        printf "\e[u"
    fi
}

updateCalendar() {
    local tmp_file="$HOME/.cache/fastfetch/myCalendar.tmp"
    local final_file="$HOME/.cache/fastfetch/myCalendar"

    # 1. Events: Future only, Green, Limit 4, replace ':' with '➜'
    printf "${CLR_ULINE}Events:${CLR_NO_ULINE}\n" > "$tmp_file"
    # 'eventsFrom:now' ensures no past events are shown
    icalbuddy -f -nrd -nc -ss "" -lim 4 eventsFrom:now to:today+7 2>/dev/null | \
        sed "s/: / ➜ /" | \
        sed "s/^/${CLR_GREEN}/" | \
        fold -w ${FF_WIDTH} -s >> "$tmp_file"

    printf "\n${CLR_ULINE}Reminders:${CLR_NO_ULINE}\n" >> "$tmp_file"
    # 2. Reminders: Green, replace ':' with '➜'
    # Note: icalbuddy automatically pulls list names (Tinkering/Courses)
    # into the parentheses if they are categorized in the Reminders app.
    icalbuddy -f -nrd -ss "" uncompletedTasks 2>/dev/null | \
        sed "s/: / ➜ /" | \
        sed "s/^/${CLR_GREEN}/" | \
        fold -w ${FF_WIDTH} -s >> "$tmp_file"

    # Append reset code to stop green bleeding into the rest of the terminal
    printf "${CLR_RESET}" >> "$tmp_file"

    mv "$tmp_file" "$final_file"
}

updateFetch() {
    cacheFF() {
        local module=$1
        local target="$HOME/.cache/fastfetch/$2"
        fastfetch --config none --structure "$module" --logo none | sed 's/^[^:]*: //' > "$target.tmp"
        mv "$target.tmp" "$target"
    }

    cacheFF "wm" "myWM"
    cacheFF "packages" "myPackages"
    cacheFF "terminal" "myTerminal"
    cacheFF "shell" "myShell"
    cacheFF "editor" "myEditor"
}

hideTTY
fastfetch
positionCalendar
setupCompletions
setupKeybinds
restoreTTY

(updateFetch; updateCalendar) &!

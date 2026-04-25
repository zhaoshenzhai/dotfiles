export FF_LINES_UP=16
export FF_COLUMN=80
export FF_WIDTH=60

renderCalendar() {
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

updateFetch() {
    cache_ff() {
        local module=$1
        local target="$HOME/.cache/fastfetch/$2"
        fastfetch --config none --structure "$module" --logo none | sed 's/^[^:]*: //' > "$target.tmp"
        mv "$target.tmp" "$target"
    }

    cache_ff "wm" "myWM"
    cache_ff "packages" "myPackages"
    cache_ff "terminal" "myTerminal"
    cache_ff "shell" "myShell"
    cache_ff "editor" "myEditor"

    env -u DYLD_INSERT_LIBRARIES icalBuddy -sc -b "• " -ab "❗️ " eventsToday uncompletedTasks 2>/dev/null | \
        fold -w ${FF_WIDTH} -s > ~/.cache/fastfetch/myCalendar.tmp
    mv ~/.cache/fastfetch/myCalendar.tmp ~/.cache/fastfetch/myCalendar
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

if [[ -t 0 ]]; then
    stty -echo 2>/dev/null
fi

fastfetch
renderCalendar
setupCompletions
setupKeybinds
updateFetch &!
restoreTTY

CLR_LINES_UP=15
CLR_COLUMN=80
CLR_WIDTH=120
CLR_GREEN=$'\e[0;32m'
CLR_RESET=$'\e[0m'

setupColors() {
    export YELLOW='\033[0;33m'
    export PURPLE='\033[0;35m'
    export GREEN='\033[0;32m'
    export CYAN='\033[0;36m'
    export BLUE='\033[0;34m'
    export RED='\033[0;31m'
    export NC='\033[0m'
}

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

setupKeybinds() {
    bindkey '^[[Z' autosuggest-accept
    bindkey '^k' up-line-or-history
    bindkey '^j' down-line-or-history
    bindkey '^h' backward-char
    bindkey '^l' forward-char
    bindkey '^x' delete-char
}

setupCompletions() {
    autoload -Uz compinit
    local zcompdump="$HOME/.config/zsh/.zcompdump"

    if [[ -f "$zcompdump" ]]; then
        compinit -C -d "$zcompdump"
    else
        compinit -d "$zcompdump"
    fi
}

renderCalendar() {
    local cal_file="$HOME/.cache/fastfetch/myCalendar"
    if [[ -f "$cal_file" ]]; then
        printf "\e[%dA" "$CLR_LINES_UP"

        awk -v col="$CLR_COLUMN" -v lines_up="$CLR_LINES_UP" '
            {
                printf "\033[%dG\033[K%s\n", col, $0
            }
            END {
                remaining = lines_up - NR
                if (remaining > 0) {
                    printf "\033[%dB", remaining
                }
            }
        ' "$cal_file"
    fi
}

redrawDashboard() {
    local frame_file="$HOME/.cache/fastfetch/frame_full"
    [[ -n "$VIFM_FLOAT" ]] && frame_file="$HOME/.cache/fastfetch/frame_float"

    if [[ -f "$HOME/.cache/fastfetch/.first_prompt" ]] && [[ -f "$frame_file" ]]; then
        local DASHBOARD_LINES=18

        printf "\e[?25l\e7\e[%dA\e[1G" "$DASHBOARD_LINES"
        cat "$frame_file"
        printf "\e8\e[?25h"
    fi
}

updateCalendar() {
    local tmp_file="$HOME/.cache/fastfetch/myCalendar.$$.tmp"
    local final_file="$HOME/.cache/fastfetch/myCalendar"

    {
        printf "%sEvents%s ➜\n" "$CLR_GREEN" "$CLR_RESET"
        icalbuddy -f -n -nc -li 6 -ps "/ » /" -npn \
            -eep "url,location,notes,attendees" \
            -ec "Canadian Holidays,United States holidays,zhaoshen.zhai@gmail.com" \
            eventsFrom:now to:today+100 2>/dev/null | \
            awk -v l="$CLR_WIDTH" '{ if (length($0) > l) print substr($0, 1, l-3) "..."; else print $0 }'

        printf "\n"

        printf "%sReminders%s ➜\n" "$CLR_GREEN" "$CLR_RESET"
        icalbuddy -li 6 uncompletedTasks | sed 's/ (Reminders)//g' 2>/dev/null | \
            awk -v l="$CLR_WIDTH" '{ if (length($0) > l) print substr($0, 1, l-3) "..."; else print $0 }'

        printf "%s" "$CLR_RESET"
    } > "$tmp_file"

    mv "$tmp_file" "$final_file"
}

updateFetch() {
    local cache_dir="$HOME/.cache/fastfetch"

    writeCache() {
        printf "%s\033[K\n" "$2" > "$cache_dir/$1.$$.tmp"
        mv "$cache_dir/$1.$$.tmp" "$cache_dir/$1"
    }

    local raw_data
    raw_data=$(fastfetch --config none --structure Packages:OS:Host:CPU:Kernel:Uptime:Terminal:Shell:Editor:Monitor:WM:TerminalFont:Weather:Media --logo none)

    extract() {
        echo "$raw_data" | grep "^$1:" | sed "s/^$1: //"
    }

    local pkgs_raw
    pkgs_raw=$(extract "Packages")
    writeCache "myNix" "$(echo "$pkgs_raw" | sed -E 's/[0-9]+ \(brew[^)]*\), //g; s/nix-//g; s/default/user/g')"
    writeCache "myBrew" "$(echo "$pkgs_raw" | sed -E 's/, [0-9]+ \(nix-[^)]*\)//g; s/brew-cask/cask/g')"

    writeCache "myOS"       "$(extract "OS")"
    writeCache "myHost"     "$(extract "Host")"
    writeCache "myCPU"      "$(extract "CPU")"
    writeCache "myKernel"   "$(extract "Kernel")"
    writeCache "myUptime"   "$(extract "Uptime")"
    writeCache "myTerminal" "$(extract "Terminal")"
    writeCache "myShell"    "$(extract "Shell")"
    writeCache "myEditor"   "$(extract "Editor")"
    writeCache "myMonitor"  "$(extract "Monitor (Color LCD)" | sed 's/ -.*//g')"
    writeCache "myWM"       "$(extract "WM"                  | grep -o 'AeroSpace [^)]*')"
    writeCache "myFont"     "$(extract "Terminal Font"       | sed 's/Menlo/Courier Prime/g')"
    writeCache "myWeather"  "$(extract "Weather"             | sed 's/ (.*)//g')"

    writeCache "myMedia"    "$(extract "Media" | sed 's/ ([^)]*)$//' | awk -F ' - ' '{ a=$1; t=$2; if(length(a)>15) a=substr(a,1,12)"..."; if(length(t)>17) t=substr(t,1,14)"..."; if(NF>1) print a " - " t; else print substr($0,1,32)"..." }')"
}

updateAsync() {
    updateFetch
    updateCalendar

    fastfetch --pipe false | awk '{printf "%s\033[K\n", $0}' > "$HOME/.cache/fastfetch/frame_float.$$.tmp"
    renderCalendar > "$HOME/.cache/fastfetch/frame_cal.$$.tmp"

    cat "$HOME/.cache/fastfetch/frame_float.$$.tmp" "$HOME/.cache/fastfetch/frame_cal.$$.tmp" > "$HOME/.cache/fastfetch/frame_full.$$.tmp"

    mv "$HOME/.cache/fastfetch/frame_full.$$.tmp" "$HOME/.cache/fastfetch/frame_full"
    mv "$HOME/.cache/fastfetch/frame_float.$$.tmp" "$HOME/.cache/fastfetch/frame_float"

    rm -f "$HOME/.cache/fastfetch/frame_cal.$$.tmp"

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

    local frame_file="$HOME/.cache/fastfetch/frame_full"
    [[ -n "$VIFM_FLOAT" ]] && frame_file="$HOME/.cache/fastfetch/frame_float"

    if [[ -f "$frame_file" ]]; then
        cat "$frame_file"
    else
        fastfetch | awk '{printf "%s\033[K\n", $0}'
        if [[ -z "$VIFM_FLOAT" ]]; then
            renderCalendar
        fi
    fi

    setupCompletions
    setupKeybinds
    setupColors
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

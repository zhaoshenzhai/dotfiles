#!/usr/bin/env bash

enforceWorkspace() {
    local alacritty_count
    local alacritty_nvim_count
    local skim_count
    local alacritty_id

    alacritty_count=$(aerospace list-windows --workspace focused --format "%{app-name}" \
        | awk 'tolower($0) ~ /^alacritty/ {c++} END {print c+0}')
    alacritty_nvim_count=$(aerospace list-windows --workspace focused --format "%{app-name}|%{window-title}" \
        | awk -F'|' 'tolower($1) ~ /^alacritty/ && tolower($2) ~ /nvim/ {c++} END {print c+0}')
    skim_count=$(aerospace list-windows --workspace focused --format "%{app-bundle-id}" \
        | awk '/net\.sourceforge\.skim-app\.skim/ {c++} END {print c+0}')

    if [ "$alacritty_count" -eq 1 ] && [ "$alacritty_nvim_count" -eq 1 ] && [ "$skim_count" -ge 1 ]; then
        alacritty_id=$(aerospace list-windows --workspace focused --format "%{window-id}|%{app-name}" | grep -i "|Alacritty" | cut -d'|' -f1 || true)

        aerospace focus --window-id "$alacritty_id"
        aerospace layout v_accordion
        aerospace move up
        aerospace focus --window-id "$alacritty_id"
    fi
}

switchFocus() {
    local direction="$1"
    local alacritty_count
    local alacritty_nvim_count
    local skim_count
    local current_workspace

    current_workspace=$(aerospace list-workspaces --focused)
    if [ -z "$current_workspace" ]; then
        aerospace focus "$direction"
        exit 0
    fi

    local memory_dir="/tmp/aerospace_skim_tabs"
    mkdir -p "$memory_dir"
    local skim_memory_file="${memory_dir}/workspace_${current_workspace}.txt"

    alacritty_count=$(aerospace list-windows --workspace focused --format "%{app-name}" \
        | awk 'tolower($0) ~ /^alacritty/ {c++} END {print c+0}')
    alacritty_nvim_count=$(aerospace list-windows --workspace focused --format "%{app-name}|%{window-title}" \
        | awk -F'|' 'tolower($1) ~ /^alacritty/ && tolower($2) ~ /nvim/ {c++} END {print c+0}')
    skim_count=$(aerospace list-windows --workspace focused --format "%{app-bundle-id}" \
        | awk '/net\.sourceforge\.skim-app\.skim/ {c++} END {print c+0}')

    if [ "$alacritty_count" -ne 1 ] || [ "$alacritty_nvim_count" -ne 1 ] || [ "$skim_count" -le 1 ]; then
        aerospace focus "$direction"
        exit 0
    fi

    local current_id
    local current_app
    local current_bundle
    local target_skim
    local saved_id
    local alacritty_id

    current_id=$(aerospace list-windows --focused --format "%{window-id}" | tr -d '[:space:]')
    current_app=$(aerospace list-windows --focused --format "%{app-name}" | xargs | tr '[:upper:]' '[:lower:]')
    current_bundle=$(aerospace list-windows --focused --format "%{app-bundle-id}" | tr -d '[:space:]')

    if [ "$current_app" == "alacritty" ]; then
        if [ "$direction" == "up" ]; then
            exit 0
        elif [ "$direction" == "down" ]; then
            target_skim=""

            if [ -f "$skim_memory_file" ]; then
                saved_id=$(cat "$skim_memory_file")
                if aerospace list-windows --workspace focused --format "%{window-id}" | grep -q "^${saved_id}$" || true; then
                    target_skim="$saved_id"
                fi
            fi

            if [ -z "$target_skim" ]; then
                target_skim=$(aerospace list-windows --workspace focused --format "%{window-id}|%{app-bundle-id}" \
                    | grep -E "net\.sourceforge\.skim-app\.skim(attic)?" | head -n 1 | cut -d'|' -f1 || true)
            fi

            if [ -n "$target_skim" ]; then
                aerospace focus --window-id "$target_skim"
            fi
            exit 0
        fi
    elif [[ "$current_bundle" == "net.sourceforge.skim-app.skim" ]]; then
        echo "$current_id" > "$skim_memory_file"

        if [ "$direction" == "down" ]; then
            exit 0
        elif [ "$direction" == "up" ]; then
            alacritty_id=$(aerospace list-windows --workspace focused --format "%{window-id}|%{app-name}" \
                | grep -i "|Alacritty" | head -n 1 | cut -d'|' -f1 || true)

            if [ -n "$alacritty_id" ]; then
                aerospace focus --window-id "$alacritty_id"
            fi
            exit 0
        fi

    else
        aerospace focus "$direction"
    fi
}

closeWindow() {
    local current_workspace
    current_workspace=$(aerospace list-workspaces --focused)

    local current_bundle
    current_bundle=$(aerospace list-windows --focused --format "%{app-bundle-id}" | tr -d '[:space:]')

    if [[ "$current_bundle" == "net.sourceforge.skim-app.skim" ]]; then
        local skim_memory_file="/tmp/aerospace_skim_tabs/workspace_${current_workspace}.txt"
        rm -f "$skim_memory_file"

        local skim_ids
        skim_ids=$(aerospace list-windows --workspace focused --format "%{window-id}|%{app-bundle-id}" \
            | awk -F'|' '/net\.sourceforge\.skim-app\.skim/ {print $1}')

        for id in $skim_ids; do
            if [ -n "$id" ]; then
                aerospace focus --window-id "$id"
                osascript -e 'tell application "Skim"' -e 'close front document' -e 'end tell'
            fi
        done
    else
        aerospace close --quit-if-last-window
    fi
}

closeSkimTab() {
    local skim_count
    skim_count=$(aerospace list-windows --workspace focused --format "%{app-bundle-id}" \
        | awk '/net\.sourceforge\.skim-app\.skim/ {c++} END {print c+0}')

    if [ "$skim_count" -gt 1 ]; then
        local current_workspace
        current_workspace=$(aerospace list-workspaces --focused)

        local current_id
        current_id=$(aerospace list-windows --focused --format "%{window-id}" | tr -d '[:space:]')

        local skim_memory_file="/tmp/aerospace_skim_tabs/workspace_${current_workspace}.txt"

        if [ -f "$skim_memory_file" ]; then
            local saved_id
            saved_id=$(cat "$skim_memory_file")
            if [ "$saved_id" == "$current_id" ]; then
                rm -f "$skim_memory_file"
            fi
        fi

        osascript -e 'tell application "Skim"' -e 'close front document' -e 'end tell'
    fi
}

recordSkim() {
    local window_id="$1"
    if [ -z "$window_id" ]; then
        exit 1
    fi

    local current_workspace
    current_workspace=$(aerospace list-workspaces --focused)

    if [ -n "$current_workspace" ]; then
        local memory_dir="/tmp/aerospace_skim_tabs"
        mkdir -p "$memory_dir"
        echo "$window_id" > "${memory_dir}/workspace_${current_workspace}.txt"
    fi
}

if [[ "${1:-}" == "--record" ]]; then
    recordSkim "$2"
    exit 0
fi

if [[ "${1:-}" == "--close" ]]; then
    closeWindow
    exit 0
fi

if [[ "${1:-}" == "--close-skim-tab" ]]; then
    closeSkimTab
    exit 0
fi

if [[ "${1:-}" == "--enforce" ]]; then
    enforceWorkspace
    exit 0
fi

if [[ -n "${1:-}" ]]; then
    switchFocus "$1"
fi

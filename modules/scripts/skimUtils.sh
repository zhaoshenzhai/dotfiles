#!/usr/bin/env bash

switchFocus() {
    local direction="$1"
    local current_workspace=$(aerospace list-workspaces --focused)
    local memory_dir="/tmp/aerospace_skim_tabs"
    local skim_memory_file="${memory_dir}/workspace_${current_workspace}.txt"
    mkdir -p "$memory_dir"

    local alacritty_count=$(aerospace list-windows --workspace focused --format "%{app-name}" \
        | awk 'tolower($0) ~ /^alacritty/ {c++} END {print c+0}')
    local alacritty_nvim_count=$(aerospace list-windows --workspace focused --format "%{app-name}|%{window-title}" \
        | awk -F'|' 'tolower($1) ~ /^alacritty/ && tolower($2) ~ /nvim/ {c++} END {print c+0}')
    local skim_count=$(aerospace list-windows --workspace focused --format "%{app-bundle-id}" \
        | awk '/net\.sourceforge\.skim-app\.skim/ {c++} END {print c+0}')

    if [ "$alacritty_count" -ne 1 ] || [ "$alacritty_nvim_count" -ne 1 ] || [ "$skim_count" -le 1 ]; then
        aerospace focus "$direction"
        exit 0
    fi

    local current_id=$(aerospace list-windows --focused --format "%{window-id}" | tr -d '[:space:]')
    local current_app=$(aerospace list-windows --focused --format "%{app-name}" | xargs | tr '[:upper:]' '[:lower:]')
    local current_bundle=$(aerospace list-windows --focused --format "%{app-bundle-id}" | tr -d '[:space:]')

    if [ "$current_app" == "alacritty" ]; then
        if [ "$direction" == "up" ]; then
            exit 0
        elif [ "$direction" == "down" ]; then
            local target_skim=""

            if [ -f "$skim_memory_file" ]; then
                local saved_id=$(cat "$skim_memory_file")
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
            local alacritty_id=$(aerospace list-windows --workspace focused --format "%{window-id}|%{app-name}" \
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

focusDaemon() {
    local PIPE="/tmp/skim_focus_pipe"
    rm -f "$PIPE"
    mkfifo "$PIPE"

    local ORIGINAL_COLOR="0"
    local PREV_APP=""
    local ENABLED=0

    local BUNDLE_SKIM="net.sourceforge.skim-app.skim"

    while true; do
        if read -r PAYLOAD < "$PIPE"; then
            [ -z "$PAYLOAD" ] && continue

            if [ "$PAYLOAD" == "TOGGLE_STATE" ]; then
                if [ "$ENABLED" -eq 1 ]; then
                    ENABLED=0
                else
                    ENABLED=1
                fi
                continue
            elif [ "$PAYLOAD" == "DISABLE_STATE" ]; then
                ENABLED=0
                continue
            fi

            local FOCUSED_APP="$PAYLOAD"

            if [ "$FOCUSED_APP" != "$PREV_APP" ]; then
                if [ "$ENABLED" -eq 1 ]; then
                    if [[ "$PREV_APP" == "Skim" ]] && [[ "$FOCUSED_APP" != "Skim" ]]; then
                        ORIGINAL_COLOR=$(defaults read "$BUNDLE_SKIM" SKInvertColorsInDarkMode 2>/dev/null || echo 0)

                        if [ "$ORIGINAL_COLOR" != "1" ]; then
                            defaults write "$BUNDLE_SKIM" SKInvertColorsInDarkMode -bool true
                        fi
                    fi

                    if [[ "$FOCUSED_APP" == "Skim" ]] && [[ "$PREV_APP" != "Skim" ]]; then
                        local CURRENT=$(defaults read "$BUNDLE_SKIM" SKInvertColorsInDarkMode 2>/dev/null || echo 0)
                        if [ "$CURRENT" != "$ORIGINAL_COLOR" ]; then
                            if [ "$ORIGINAL_COLOR" == "1" ]; then
                                defaults write "$BUNDLE_SKIM" SKInvertColorsInDarkMode -bool true
                            else
                                defaults write "$BUNDLE_SKIM" SKInvertColorsInDarkMode -bool false
                            fi
                        fi
                    fi
                fi

                PREV_APP="$FOCUSED_APP"
            fi
        fi
    done
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

enforceSkim() {
    local alacritty_count=$(aerospace list-windows --workspace focused --format "%{app-name}" \
        | awk 'tolower($0) ~ /^alacritty/ {c++} END {print c+0}')
    local alacritty_nvim_count=$(aerospace list-windows --workspace focused --format "%{app-name}|%{window-title}" \
        | awk -F'|' 'tolower($1) ~ /^alacritty/ && tolower($2) ~ /nvim/ {c++} END {print c+0}')
    local skim_count=$(aerospace list-windows --workspace focused --format "%{app-bundle-id}" \
        | awk '/net\.sourceforge\.skim-app\.skim/ {c++} END {print c+0}')

    if [ "$alacritty_count" -eq 1 ] && [ "$alacritty_nvim_count" -eq 1 ] && [ "$skim_count" -ge 1 ]; then
        local alacritty_id=$(aerospace list-windows --workspace focused --format "%{window-id}|%{app-name}" \
            | grep -i "|Alacritty" | cut -d'|' -f1 || true)

        aerospace focus --window-id "$alacritty_id"
        aerospace layout v_accordion
        aerospace move up
        aerospace focus --window-id "$alacritty_id"
    fi
}

# Main
case "${1:-}" in
    --switchFocus)
        switchFocus "$2"
        exit 0
        ;;
    --focusDaemon)
        focusDaemon
        exit 0
        ;;
    --recordSkim)
        recordSkim "$2"
        exit 0
        ;;
    --enforceSkim)
        enforceSkim
        exit 0
        ;;
    *)
        echo "Usage: $(basename "$0") [--switchFocus <dir> | --focusDaemon | --recordSkim <id> | --enforceSkim]"
        exit 1
        ;;
esac

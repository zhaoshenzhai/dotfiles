#!/usr/bin/env bash

SKIM_MEMORY_FILE="/tmp/aerospace_last_skim_id"

enforceWorkspace() {
    local alacritty_count
    local skim_count
    local alacritty_id

    aerospace list-windows --workspace focused --format "%{window-id}|%{app-name}"

    alacritty_count=$(aerospace list-windows --workspace focused --format "%{app-name}" \
        | awk 'tolower($0) ~ /^alacritty/ {c++} END {print c+0}')
    skim_count=$(aerospace list-windows --workspace focused --format "%{app-name}" | awk 'tolower($0) ~ /^skim/ {c++} END {print c+0}')

    if [ "$alacritty_count" -eq 1 ] && [ "$skim_count" -ge 1 ]; then
        alacritty_id=$(aerospace list-windows --workspace focused --format "%{window-id}|%{app-name}" \
            | grep -i "|Alacritty" | cut -d'|' -f1 || true)

        aerospace focus --window-id "$alacritty_id"
        aerospace layout v_accordion
        aerospace move up
        aerospace focus --window-id "$alacritty_id"
    fi
}
switchFocus() {
    local direction="$1"
    local alacritty_count
    local skim_count

    aerospace list-windows --workspace focused --format "%{window-id}|%{app-name}"

    alacritty_count=$(aerospace list-windows --workspace focused --format "%{app-name}" \
        | awk 'tolower($0) ~ /^alacritty/ {c++} END {print c+0}')
    skim_count=$(aerospace list-windows --workspace focused --format "%{app-name}" | awk 'tolower($0) ~ /^skim/ {c++} END {print c+0}')

    if [ "$alacritty_count" -ne 1 ] || [ "$skim_count" -lt 1 ]; then
        aerospace focus "$direction"
        exit 0
    fi

    local current_id
    local current_app
    local target_skim
    local saved_id
    local alacritty_id

    current_id=$(aerospace list-windows --focused --format "%{window-id}" | tr -d '[:space:]')
    current_app=$(aerospace list-windows --focused --format "%{app-name}" | xargs | tr '[:upper:]' '[:lower:]')

    if [ "$current_app" == "alacritty" ]; then
        if [ "$direction" == "up" ]; then
            exit 0
        elif [ "$direction" == "down" ]; then
            target_skim=""

            if [ -f "$SKIM_MEMORY_FILE" ]; then
                saved_id=$(cat "$SKIM_MEMORY_FILE")
                if aerospace list-windows --workspace focused --format "%{window-id}" | grep -q "^${saved_id}$" || true; then
                    target_skim="$saved_id"
                fi
            fi

            if [ -z "$target_skim" ]; then
                target_skim=$(aerospace list-windows --workspace focused --format "%{window-id}|%{app-name}" \
                    | grep -i "|Skim" | head -n 1 | cut -d'|' -f1 || true)
            fi

            if [ -n "$target_skim" ]; then
                aerospace focus --window-id "$target_skim"
            fi
            exit 0
        fi
    elif [ "$current_app" == "skim" ]; then
        echo "$current_id" > "$SKIM_MEMORY_FILE"

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

if [[ "${1:-}" == "--enforce" ]]; then
    enforceWorkspace
    exit 0
fi

if [[ -n "${1:-}" ]]; then
    switchFocus "$1"
fi

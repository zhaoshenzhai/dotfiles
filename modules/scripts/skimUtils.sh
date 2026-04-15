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

cleanSkimState() {
    local current_workspace=$(aerospace list-workspaces --focused)
    local skim_memory_file="/tmp/aerospace_skim_tabs/workspace_${current_workspace}.txt"

    if [ -f "$skim_memory_file" ]; then
        local saved_id=$(cat "$skim_memory_file")
        if ! aerospace list-windows --all --format "%{window-id}" | grep -q "^${saved_id}$"; then
            rm -f "$skim_memory_file"
        fi
    fi

    if [ -d "/tmp/skim_pdfs" ]; then
        local current_time=$(date +%s)
        for dir in /tmp/skim_pdfs/*/; do
            if [ -d "$dir" ]; then
                local dir_timestamp=$(basename "$dir")
                if [[ "$dir_timestamp" =~ ^[0-9]+$ ]]; then
                    local age_in_seconds=$((current_time - dir_timestamp))
                    if (( age_in_seconds > 86400 )); then
                        rm -rf "$dir"
                    fi
                fi
            fi
        done
    fi
}

duplicateTab() {
    local result=$(osascript -e '
        tell application "Skim"
            if (count of documents) > 0 then
                try
                    set docPath to path of document 1
                    set currPage to index of current page of document 1
                    return docPath & "|" & currPage
                on error
                    return "|"
                end try
            else
                return "|"
            end if
        end tell
    ' 2>/dev/null)

    local doc_path="${result%|*}"
    local curr_page="${result#*|}"

    if [ -z "$doc_path" ] || [ "$doc_path" == "missing value" ]; then
        exit 0
    fi

    local launch_path="$doc_path"
    if [[ "$doc_path" == */tmp/skim_pdfs/* ]] && [ -f "${doc_path}.orig" ]; then
        launch_path=$(cat "${doc_path}.orig")
    fi

    nohup /etc/profiles/per-user/$USER/bin/launcher "$launch_path" >/dev/null 2>&1 &

    if [[ -n "$curr_page" && "$curr_page" =~ ^[0-9]+$ ]]; then
        osascript -e "
            tell application \"Skim\"
                set retries to 25
                repeat while retries > 0
                    delay 0.05
                    try
                        set frontDoc to document 1
                        if (path of frontDoc) is not \"$doc_path\" then
                            set current page of frontDoc to page $curr_page of frontDoc
                            exit repeat
                        end if
                    end try
                    set retries to retries - 1
                end repeat
            end tell
        " & disown
    fi
}

openRelated() {
    local ext="$1"
    local FRONT_BUNDLE=$(osascript -e 'id of application (path to frontmost application as text)' 2>/dev/null)
    local PDF_PATH=$(osascript -e "tell application id \"$FRONT_BUNDLE\" to get path of document of window 1" 2>/dev/null)

    if [ -z "$PDF_PATH" ] || [ "$PDF_PATH" == "missing value" ]; then
        exit 0
    fi

    if [[ "$PDF_PATH" == */tmp/skim_pdfs/* ]] && [ -f "${PDF_PATH}.orig" ]; then
        PDF_PATH=$(cat "${PDF_PATH}.orig")
    fi

    local SEARCH_STR="Library/Mobile Documents/com~apple~CloudDocs"
    if [[ "$PDF_PATH" == *"$SEARCH_STR"* ]]; then
        PDF_PATH="${PDF_PATH/$SEARCH_STR/iCloud}"
    fi

    local TARGET_PATH="${PDF_PATH%.pdf}.$ext"
    if [ -f "$TARGET_PATH" ]; then
        nohup /etc/profiles/per-user/$USER/bin/launcher "$TARGET_PATH" >/dev/null 2>&1 &
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

exportAtticFile() {
    local FRONT_BUNDLE=$(osascript -e 'id of application (path to frontmost application as text)' 2>/dev/null)
    local PDF_PATH=$(osascript -e "tell application id \"$FRONT_BUNDLE\" to get path of document of window 1" 2>/dev/null)

    if [ -z "$PDF_PATH" ] || [ "$PDF_PATH" == "missing value" ]; then
        exit 0
    fi

    if [[ "$PDF_PATH" == */tmp/skim_pdfs/* ]] && [ -f "${PDF_PATH}.orig" ]; then
        PDF_PATH=$(cat "${PDF_PATH}.orig")
    fi

    local TEX_PATH="${PDF_PATH%.pdf}.tex"
    if [ -z "$TEX_PATH" ]; then
        exit 0
    fi

    cp -f "$PDF_PATH" "/Users/zhao/Downloads/"
    cp -f "$TEX_PATH" "/Users/zhao/Downloads/"
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
    --cleanSkimState)
        cleanSkimState
        exit 0
        ;;
    --duplicateTab)
        duplicateTab
        exit 0
        ;;
    --openNvim|--openTex)
        openRelated "tex"
        exit 0
        ;;
    --openKey)
        openRelated "key"
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
    --exportAtticFile)
        exportAtticFile
        exit 0
        ;;
    *)
        echo "Usage: $(basename "$0") [--switchFocus <dir> | --focusDaemon | --cleanSkimState | --duplicateTab | --openNvim | --openTex | --openKey | --recordSkim <id> | --enforceSkim | --exportAtticFile]"
        exit 1
        ;;
esac

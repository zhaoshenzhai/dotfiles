#!/usr/bin/env bash

open_nvim() {
    local FRONT_BUNDLE
    FRONT_BUNDLE=$(osascript -e 'id of application (path to frontmost application as text)' 2>/dev/null)

    local PDF_PATH
    PDF_PATH=$(osascript -e "tell application id \"$FRONT_BUNDLE\" to get path of document of window 1" 2>/dev/null)

    if [ -z "$PDF_PATH" ] || [ "$PDF_PATH" == "missing value" ]; then
        exit 0
    fi

    local TEX_PATH="${PDF_PATH%.pdf}.tex"
    if [ -f "$TEX_PATH" ]; then
        nohup /etc/profiles/per-user/zhao/bin/launcher "$TEX_PATH" >/dev/null 2>&1 &
    fi
}

focus_daemon() {
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

while getopts "odc" opt; do
    case $opt in
        o) open_nvim; exit 0 ;;
        d) focus_daemon; exit 0 ;;
        *) echo "Usage: $(basename "$0") -o (Open Neovim) | -d (Start Focus Daemon)"; exit 1 ;;
    esac
done

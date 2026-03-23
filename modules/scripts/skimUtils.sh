#!/usr/bin/env bash

open_nvim() {
    local PDF_PATH
    PDF_PATH=$(osascript -e 'tell application "Skim" to get path of document 1' 2>/dev/null)
    if [ -z "$PDF_PATH" ]; then
        exit 0
    fi

    local TEX_PATH="${PDF_PATH%.pdf}.tex"
    if [ -f "$TEX_PATH" ]; then
        local NVIM_PATH="/etc/profiles/per-user/$USER/bin/nvim"
        local HM_SESSION="$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
        local EXEC_CMD="[ -f $HM_SESSION ] && . $HM_SESSION; exec $NVIM_PATH \"$TEX_PATH\""
        nohup alacritty -e sh -c "$EXEC_CMD" >/dev/null 2>&1 &
    fi
}

focus_daemon() {
    local PIPE="/tmp/skim_focus_pipe"
    rm -f "$PIPE"
    mkfifo "$PIPE"

    local ORIGINAL_COLOR="0"
    local PREV_APP=""
    local ENABLED=0

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
                    if [ "$PREV_APP" == "Skim" ]; then
                        ORIGINAL_COLOR=$(defaults read net.sourceforge.skim-app.skim SKInvertColorsInDarkMode 2>/dev/null || echo 0)

                        if [ "$ORIGINAL_COLOR" != "1" ]; then
                            defaults write net.sourceforge.skim-app.skim SKInvertColorsInDarkMode -bool true
                        fi
                    fi

                    if [ "$FOCUSED_APP" == "Skim" ]; then
                        local CURRENT=$(defaults read net.sourceforge.skim-app.skim SKInvertColorsInDarkMode 2>/dev/null || echo 0)
                        if [ "$CURRENT" != "$ORIGINAL_COLOR" ]; then
                            if [ "$ORIGINAL_COLOR" == "1" ]; then
                                defaults write net.sourceforge.skim-app.skim SKInvertColorsInDarkMode -bool true
                            else
                                defaults write net.sourceforge.skim-app.skim SKInvertColorsInDarkMode -bool false
                            fi
                        fi
                    fi
                fi

                PREV_APP="$FOCUSED_APP"
            fi
        fi
    done
}

while getopts "od" opt; do
  case $opt in
    o) open_nvim; exit 0 ;;
    d) focus_daemon; exit 0 ;;
    *) echo "Usage: $(basename "$0") -o (Open Neovim) | -d (Start Focus Daemon)"; exit 1 ;;
  esac
done

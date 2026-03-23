#!/usr/bin/env bash

PDF_PATH=$(osascript -e 'tell application "Skim" to get path of document 1' 2>/dev/null)
if [ -z "$PDF_PATH" ]; then
    exit 0
fi

TEX_PATH="${PDF_PATH%.pdf}.tex"
if [ -f "$TEX_PATH" ]; then
    NVIM_PATH="/etc/profiles/per-user/$USER/bin/nvim"
    HM_SESSION="$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    EXEC_CMD="[ -f $HM_SESSION ] && . $HM_SESSION; exec $NVIM_PATH \"$TEX_PATH\""
    nohup alacritty -e sh -c "$EXEC_CMD" >/dev/null 2>&1 &
fi

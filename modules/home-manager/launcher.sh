#!/usr/bin/env bash

LOCKFILE="/tmp/launcher.lock"
if [ -f "$LOCKFILE" ]; then
    OLD_PID=$(cat "$LOCKFILE")
    if ps -p "$OLD_PID" > /dev/null; then
        exit 0
    fi
fi
echo $$ > "$LOCKFILE"
trap "rm -f $LOCKFILE" EXIT

CACHE_DIR="$HOME/.cache/launcher"
CACHE_FILE="$CACHE_DIR/files.txt"
RECENT_FILE="$CACHE_DIR/recent.txt"

mkdir -p "$CACHE_DIR"
touch "$RECENT_FILE"

(
    fd --type f --hidden --exclude .git . \
        "/Users/zhao/iCloud/Documents" \
        "/Users/zhao/iCloud/Dotfiles" > "$CACHE_FILE.tmp" 2>/dev/null
    mv "$CACHE_FILE.tmp" "$CACHE_FILE"
) &

SELECTED=$(cat "$RECENT_FILE" "$CACHE_FILE" 2>/dev/null | awk '!seen[$0]++' | fzf \
    --reverse \
    --info=hidden \
    --delimiter / \
    --tiebreak=index \
    --pointer='➜')

if [ -z "$SELECTED" ]; then
    exit 0
fi

grep -vF -x "$SELECTED" "$RECENT_FILE" > "$RECENT_FILE.tmp" 2>/dev/null || true
echo "$SELECTED" | cat - "$RECENT_FILE.tmp" | head -n 100 > "$RECENT_FILE"
rm -f "$RECENT_FILE.tmp"

if [[ "$SELECTED" == /Users/zhao/iCloud/Dotfiles* ]]; then
    NVIM_PATH="/etc/profiles/per-user/$USER/bin/nvim"
    HM_SESSION="$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    EXEC_CMD="[ -f $HM_SESSION ] && . $HM_SESSION; export FROM_LAUNCHER=1; exec $NVIM_PATH \"$SELECTED\""
    
    nohup alacritty -e sh -c "$EXEC_CMD" >/dev/null 2>&1 &
elif [[ "$SELECTED" == /Users/zhao/iCloud/Documents* ]]; then
    open -n -a Skim "$SELECTED" >/dev/null 2>&1 &
fi

aerospace mode main
sleep 0.5

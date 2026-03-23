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
    cd "/Users/zhao/iCloud" || exit
    fd --type f --hidden --exclude .git --exclude '*.old' . \
        "Documents" "Dotfiles" "Projects" | while read -r line; do

        if [[ "$line" =~ Projects/_attic/([0-9]{5})/([0-9]{5})\.tex ]]; then
            ID="${BASH_REMATCH[1]}"
            KW_PATH="/Users/zhao/iCloud/Projects/_attic/$ID/keywords"
            if [ -f "$KW_PATH" ]; then
                KW=$(tr '\n' ',' < "$KW_PATH" | sed 's/,$//')
                echo -e "Projects/_attic/[$KW]\t$line"
                continue
            fi
        elif [[ "$line" =~ Projects/_attic/([0-9]{5})/keywords ]]; then
            ID="${BASH_REMATCH[1]}"
            KW_PATH="/Users/zhao/iCloud/Projects/_attic/$ID/keywords"
            if [ -f "$KW_PATH" ]; then
                KW=$(tr '\n' ',' < "$KW_PATH" | sed 's/,$//')
                echo -e "Projects/_attic/[$KW]/keywords\t$line"
                continue
            fi
        fi

        echo -e "$line\t$line"
    done > "$CACHE_FILE.tmp" 2>/dev/null
    mv "$CACHE_FILE.tmp" "$CACHE_FILE"
) &

SELECTED_LINE=$(cat "$RECENT_FILE" "$CACHE_FILE" 2>/dev/null | awk '!seen[$0]++' | fzf \
    --reverse \
    --info=hidden \
    --delimiter '\t' \
    --with-nth 1 \
    --tiebreak=index \
    --pointer='➜')

if [ -z "$SELECTED_LINE" ]; then exit 0; fi

grep -vF -x "$SELECTED_LINE" "$RECENT_FILE" > "$RECENT_FILE.tmp" 2>/dev/null || true
echo "$SELECTED_LINE" | cat - "$RECENT_FILE.tmp" | head -n 100 > "$RECENT_FILE"
rm -f "$RECENT_FILE.tmp"

RELATIVE_PATH=$(echo "$SELECTED_LINE" | cut -f2)
FULL_PATH="/Users/zhao/iCloud/$RELATIVE_PATH"

if [[ "$FULL_PATH" == *.pdf ]]; then
    open -n -a Skim "$FULL_PATH" >/dev/null 2>&1 &
else
    NVIM_PATH="/etc/profiles/per-user/$USER/bin/nvim"
    HM_SESSION="$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    EXEC_CMD="[ -f $HM_SESSION ] && . $HM_SESSION; export FROM_LAUNCHER=1; exec $NVIM_PATH \"$FULL_PATH\""

    nohup alacritty -e sh -c "$EXEC_CMD" >/dev/null 2>&1 &
fi

aerospace mode main
sleep 0.5

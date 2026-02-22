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

declare -a RULES=(
    "/Users/zhao/iCloud/Documents|skim"
    "/Users/zhao/iCloud/Dotfiles|nvim"
)

SEARCH_DIRS=()
for rule in "${RULES[@]}"; do
    DIR="${rule%%|*}"
    if [ -d "$DIR" ]; then
        SEARCH_DIRS+=("$DIR")
    fi
done

ALL_FILES=$(find "${SEARCH_DIRS[@]}" -type f -not -path '*/.*' -maxdepth 10 -print0 | xargs -0 ls -dtu 2>/dev/null)
SELECTED=$(echo "$ALL_FILES" | sed '/^$/d' | fzf \
    --reverse \
    --info=hidden \
    --delimiter / \
    --tiebreak=index \
    --pointer='➜')

if [ -z "$SELECTED" ]; then
    exit 0
fi

touch -a "$SELECTED"

CMD="open"
for rule in "${RULES[@]}"; do
    DIR="${rule%%|*}"
    APP="${rule#*|}"
    
    if echo "$SELECTED" | grep -q -i "^$DIR"; then
        CMD="$APP"
        break
    fi
done

if [[ "$CMD" == "nvim" ]]; then
    NVIM_PATH="/etc/profiles/per-user/$USER/bin/nvim"
    HM_SESSION="$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    EXEC_CMD="[ -f $HM_SESSION ] && . $HM_SESSION; exec $NVIM_PATH \"$SELECTED\""
    
    nohup alacritty -e zsh -c "$EXEC_CMD" >/dev/null 2>&1 &
elif [[ "$CMD" == "skim" ]]; then
    open -n -a Skim "$SELECTED" >/dev/null 2>&1 &
fi

/etc/profiles/per-user/zhao/bin/aerospace mode main
sleep 0.1
exit 0

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
    "$HOME/iCloud/Documents|zathura"
    "$HOME/nix|nvim"
)

ALL_FILES=""
for rule in "${RULES[@]}"; do
    DIR="${rule%%|*}"
    if [ -d "$DIR" ]; then
        FOUND=$(find "$DIR" -type f -not -path '*/.*' -maxdepth 5 2>/dev/null)
        ALL_FILES="$ALL_FILES$FOUND"$'\n'
    fi
done

SELECTED=$(echo "$ALL_FILES" | sed '/^$/d' | fzf \
    --reverse \
    --info=hidden \
    --delimiter / \
    --with-nth -1)

if [ -z "$SELECTED" ]; then
    exit 0
fi

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
elif [[ "$CMD" == "open" ]]; then
    /usr/bin/open "$SELECTED"
else
    nohup "$CMD" "$SELECTED" >/dev/null 2>&1 &
fi

aerospace mode main
sleep 0.5
exit 0

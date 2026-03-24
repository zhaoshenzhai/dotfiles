#!/usr/bin/env bash

LOCKFILE="/tmp/launcher.lock"
CACHE_DIR="$HOME/.cache/launcher"
CACHE_FILE="$CACHE_DIR/files.txt"
RECENT_FILE="$CACHE_DIR/recent.txt"
BASE_DIR="$HOME/iCloud"

selectFiles() {
    cat "$RECENT_FILE" "$CACHE_FILE" 2>/dev/null | awk '!seen[$0]++' | while IFS=$'\t' read -r col1 col2; do
        if [[ -n "$col2" && -e "$BASE_DIR/$col2" ]]; then
            printf "%s\t%s\n" "$col1" "$col2"
        fi
    done | fzf \
        --reverse \
        --info=hidden \
        --delimiter '\t' \
        --with-nth 1 \
        --tiebreak=index \
        --pointer='➜'
}
launch() {
    selected="$1"
    rel_path=$(echo "$selected" | cut -f2)
    full_path="$BASE_DIR/$rel_path"

    if [[ "$full_path" == *.pdf ]]; then
        open -n -a Skim "$full_path" >/dev/null 2>&1 &
    else
        nvim_path="/etc/profiles/per-user/$USER/bin/nvim"
        hm_session="$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
        exec_cmd="[ -f $hm_session ] && . $hm_session; export FROM_LAUNCHER=1; exec $nvim_path \"$full_path\""

        nohup alacritty -e sh -c "$exec_cmd" >/dev/null 2>&1 &
    fi
}

# Init
if [ -f "$LOCKFILE" ]; then
    oldPID=$(cat "$LOCKFILE")
    if ps -p "$oldPID" > /dev/null; then
        exit 0
    fi
fi
echo $$ > "$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT

mkdir -p "$CACHE_DIR"
touch "$RECENT_FILE"
touch "$CACHE_FILE"
# Update cache
(
    cd "$BASE_DIR"
    fd --type f --hidden --exclude .git --exclude '*.old' . \
        "Documents" "Dotfiles" "Projects" | while read -r line; do

        if [[ "$line" =~ _attic/[0-9]{5}/metadata\.tex ]]; then
            continue
        fi

        if [[ "$line" =~ Projects/_attic/([0-9]{5})/([0-9]{5})\.tex ]]; then
            id="${BASH_REMATCH[1]}"
            keywordsPath="$BASE_DIR/Projects/_attic/$id/keywords"
            if [ -f "$keywordsPath" ]; then
                keywords=$(cat "$keywordsPath" 2>/dev/null)
                echo -e "Projects/attic_$id/[$keywords]\t$line"
                continue
            fi
        elif [[ "$line" =~ Projects/_attic/([0-9]{5})/keywords ]]; then
            id="${BASH_REMATCH[1]}"
            keywordsPath="$BASE_DIR/Projects/_attic/$id/keywords"
            if [ -f "$keywordsPath" ]; then
                keywords=$(cat "$keywordsPath" 2>/dev/null)
                echo -e "Projects/attic_$id/[$keywords]/keywords\t$line"
                continue
            fi
        fi

        echo -e "$line\t$line"
    done > "$CACHE_FILE.tmp" 2>/dev/null
    mv "$CACHE_FILE.tmp" "$CACHE_FILE"

    while IFS=$'\t' read -r col1 col2; do
        if [[ -z "$col2" || ! -e "$BASE_DIR/$col2" ]]; then
            continue
        fi

        valid=true

        if [[ "$col2" =~ Projects/_attic/([0-9]{5})/([0-9]{5})\.tex ]]; then
            id="${BASH_REMATCH[1]}"
            keywordsPath="$BASE_DIR/Projects/_attic/$id/keywords"
            if [ -f "$keywordsPath" ]; then
                keywords=$(cat "$keywordsPath" 2>/dev/null)
                expected="Projects/_attic/[$keywords]"
                if [[ "$col1" != "$expected" ]]; then
                    valid=false
                fi
            fi
        elif [[ "$col2" =~ Projects/_attic/([0-9]{5})/keywords ]]; then
            id="${BASH_REMATCH[1]}"
            keywordsPath="$BASE_DIR/Projects/_attic/$id/keywords"
            if [ -f "$keywordsPath" ]; then
                keywords=$(cat "$keywordsPath" 2>/dev/null)
                expected="Projects/_attic/[$keywords]/keywords"
                if [[ "$col1" != "$expected" ]]; then
                    valid=false
                fi
            fi
        fi

        if $valid; then
            printf "%s\t%s\n" "$col1" "$col2"
        fi
    done < "$RECENT_FILE" > "$RECENT_FILE.tmp"
    mv "$RECENT_FILE.tmp" "$RECENT_FILE"
) &

selected=$(selectFiles)
if [ -n "$selected" ]; then
    grep -vF -x "$selected" "$RECENT_FILE" > "$RECENT_FILE.tmp" 2>/dev/null || true
    echo "$selected" | cat - "$RECENT_FILE.tmp" | head -n 100 > "$RECENT_FILE"
    rm -f "$RECENT_FILE.tmp"

    launch "$selected"
    aerospace mode main
    sleep 0.5
fi

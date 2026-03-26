
LOCKFILE="/tmp/launcher.lock"
CACHE_DIR="$HOME/.cache/launcher"
CACHE_FILE="$CACHE_DIR/files.txt"
RECENT_FILE="$CACHE_DIR/recent.txt"
BASE_DIR="$HOME/iCloud"

init() {
    local oldPID
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
}
format() {
    local file_path="$1"

    if [[ "$file_path" =~ Projects/_attic/([0-9]{5})/([0-9]{5})\.(tex|pdf|key) ]]; then
        local id="${BASH_REMATCH[1]}"
        local ext="${BASH_REMATCH[3]}"

        local keywordsPath="$BASE_DIR/Projects/_attic/$id/$id.key"
        if [ -f "$keywordsPath" ]; then
            local keywords
            keywords=$(cat "$keywordsPath" 2>/dev/null)
            printf "Projects/attic_%s/[%s].%s\t%s\n" "$id" "$keywords" "$ext" "$file_path"
            return
        fi
    fi

    printf "%s\t%s\n" "$file_path" "$file_path"
}
updateCache() {
    cd "$BASE_DIR" || exit 1

    {
        fd --type f --hidden --exclude .git --exclude '*.old' . \
            "Documents" "Dotfiles" "Projects"
        fd --type f --hidden --no-ignore --extension pdf --exclude .git --exclude '*.old' . \
            "Documents" "Dotfiles" "Projects"
    } | awk '!seen[$0]++' | while read -r line; do
        format "$line"
    done > "$CACHE_FILE.tmp" 2>/dev/null
    mv "$CACHE_FILE.tmp" "$CACHE_FILE"

    while IFS=$'\t' read -r col1 col2; do
        if [[ -z "$col2" || ! -e "$BASE_DIR/$col2" ]]; then
            continue
        fi

        expected=$(format "$col2")

        if [[ -n "$expected" && "$expected" == "$col1"$'\t'"$col2" ]]; then
            echo "$expected"
        fi
    done < "$RECENT_FILE" > "$RECENT_FILE.tmp"
    mv "$RECENT_FILE.tmp" "$RECENT_FILE"
}
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
updateRecentFiles() {
    selected="$1"
    grep -vF -x "$selected" "$RECENT_FILE" > "$RECENT_FILE.tmp" 2>/dev/null || true
    echo "$selected" | cat - "$RECENT_FILE.tmp" | head -n 100 > "$RECENT_FILE"
    rm -f "$RECENT_FILE.tmp"
}
launch() {
    selected="$1"
    rel_path=$(echo "$selected" | cut -f2)
    full_path="$BASE_DIR/$rel_path"

    if [[ "$full_path" == *.pdf ]]; then
        if [[ "$full_path" == */Projects/_attic/* ]]; then
            ATTIC_WIN_ID=$(aerospace list-windows --all --format "%{window-id}|%{app-name}|%{window-title}" \
                | awk -F'|' '$2 == "Skim" && $3 ~ /[0-9][0-9][0-9][0-9][0-9]/ {print $1; exit}')

            if [ -n "$ATTIC_WIN_ID" ]; then
                nohup sh -c "
                    sleep 0.25
                    aerospace focus --window-id \"$ATTIC_WIN_ID\"
                    sleep 0.1
                    open -a Skim \"$full_path\"
                " >/dev/null 2>&1 &
            else
                open -n -a Skim "$full_path" >/dev/null 2>&1 &
            fi
        else
            open -n -a Skim "$full_path" >/dev/null 2>&1 &
        fi
    else
        WORKSPACE=$(aerospace list-workspaces --focused)
        NVIM_WIN_ID=$(aerospace list-windows --workspace "$WORKSPACE" --format "%{window-id}|%{app-name}|%{window-title}" \
            | awk -F'|' 'tolower($2) == "alacritty" && $3 == "nvim" {print $1; exit}')

        nvim_path="/etc/profiles/per-user/$USER/bin/nvim"
        hm_session="$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"

        if [ -n "$NVIM_WIN_ID" ]; then
            SOCKET="/tmp/nvim-window-${NVIM_WIN_ID}.sock"
            if [ -e "$SOCKET" ]; then
                aerospace focus --window-id "$NVIM_WIN_ID"
                $nvim_path --server "$SOCKET" --remote-tab "$full_path" >/dev/null 2>&1
                return
            fi
        fi

        exec_cmd="[ -f $hm_session ] && . $hm_session; export FROM_LAUNCHER=1; exec $nvim_path \"$full_path\""
        nohup alacritty -e sh -c "$exec_cmd" >/dev/null 2>&1 &
    fi
}

if [[ "${1:-}" == "--update" ]]; then
    updateCache
    exit 0
fi

init
updateCache &

selected=$(selectFiles)

if [ -n "$selected" ]; then
    updateRecentFiles "$selected"
    launch "$selected"

    sleep 0.2
    aerospace mode main
fi

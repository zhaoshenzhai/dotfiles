#!/usr/bin/env bash

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$HOME/.nix-profile/bin:$PATH"
[ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ] && . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"

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

    if [[ "$file_path" =~ Projects/_attic/notes/([0-9]{5})/([0-9]{5}).pdf ]]; then
        local id="${BASH_REMATCH[1]}"

        local keywordsPath="$BASE_DIR/Projects/_attic/notes/$id/$id.key"
        if [ -f "$keywordsPath" ]; then
            local keywords
            keywords=$(cat "$keywordsPath" 2>/dev/null)
            printf "Projects/attic_%s/[%s].pdf\t%s\n" "$id" "$keywords" "$file_path"
            return
        fi
    fi

    printf "%s\t%s\n" "$file_path" "$file_path"
}
updateCache() {
    cd "$BASE_DIR" || exit 1

    {
        fd --type f --hidden --exclude .git --exclude '*.old' \
            --exclude '*.png' --exclude '*.jpg' --exclude '*.tar.gz' --exclude '*.zip' . \
            "Documents" "Dotfiles" "Projects"
        fd --type f --hidden --no-ignore --extension pdf --exclude .git --exclude '*.old' . \
            "Documents" "Dotfiles" "Projects"
    } | grep -vE '^Projects/_attic/notes/.*\.(tex|key|dat)$' | awk '!seen[$0]++' | while read -r line; do
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

    if echo "$selected" | grep -qE '^Projects/_attic/notes/.*\.(tex|key|dat)'; then
        return
    fi

    grep -vF -x "$selected" "$RECENT_FILE" > "$RECENT_FILE.tmp" 2>/dev/null || true
    echo "$selected" | cat - "$RECENT_FILE.tmp" | head -n 100 > "$RECENT_FILE"
    rm -f "$RECENT_FILE.tmp"
}
launch() {
    selected="$1"
    rel_path=$(echo "$selected" | cut -f2)
    full_path="$BASE_DIR/$rel_path"

    if [[ "$full_path" == *.pdf ]]; then
        local filename=$(basename "$full_path")
        local pdf_tmp_base="/tmp/skim_pdfs"

        local exists=$(aerospace list-windows --all --format "%{app-name}|%{window-title}" \
            | awk -F'|' -v fname="$filename" '
                $1 == "Skim" && substr($2, 1, length(fname)) == fname {
                    print $1
                    exit
                }
            ')

        if [ -n "$exists" ]; then
            local unique_dir="$pdf_tmp_base/$(date +%s)"
            mkdir -p "$unique_dir"
            local copy_path="$unique_dir/$filename"
            cp "$full_path" "$copy_path"

            echo "$full_path" > "${copy_path}.orig"
            open -a Skim "$copy_path" >/dev/null 2>&1 &
        else
            open -a Skim "$full_path" >/dev/null 2>&1 &
        fi
    else
        WORKSPACE=$(aerospace list-workspaces --focused | xargs)
        NVIM_WIN_ID=$(aerospace list-windows --workspace "$WORKSPACE" --format "%{window-id}|%{app-name}|%{window-title}" \
            | awk -F'|' 'tolower($2) ~ /alacritty/ && (tolower($3) ~ /nvim/ || tolower($3) ~ /vim/) {print $1; exit}')

        nvim_path="/etc/profiles/per-user/$USER/bin/nvim"

        if [ -n "$NVIM_WIN_ID" ] && [ -S "/tmp/nvim-window-${NVIM_WIN_ID}.sock" ]; then
            aerospace focus --window-id "$NVIM_WIN_ID"
            $nvim_path --server "/tmp/nvim-window-${NVIM_WIN_ID}.sock" --remote-tab "$full_path" >/dev/null 2>&1 &
            return
        fi

        ARGS=("-e" "$nvim_path" "$full_path")
        alacrittyDaemon "${ARGS[@]}"
    fi
}
quit() {
    local did_launch="${1:-false}"
    local current_ws=$(aerospace list-workspaces --focused)
    local launcherID=$(aerospace list-windows --all --format "%{window-id}|%{window-title}" | awk -F'|' '$2 == "launcher" {print $1; exit}')
    if [ -z "$launcherID" ]; then
        exit 0
    fi

    if [ "$did_launch" == "true" ]; then
        local window_count=$(aerospace list-windows --workspace "$current_ws" | awk 'NF' | wc -l | tr -d ' ')
        if [ "$window_count" -le 1 ]; then
            local i=0
            while [ $i -lt 15 ]; do
                sleep 0.1
                local current_count=$(aerospace list-windows --workspace "$current_ws" | awk 'NF' | wc -l | tr -d ' ')
                if [ "$current_count" -gt 1 ]; then
                    break
                fi
                i=$((i+1))
            done
        fi
    fi

    aerospace close --window-id "$launcherID"
}

# Main
if [[ "${1:-}" == "--update" ]]; then
    updateCache
elif [[ -n "${1:-}" && -f "$1" ]]; then
    abs_path="${1/#\~/$HOME}"
    REAL_ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
    abs_path="${abs_path/$REAL_ICLOUD/$BASE_DIR}"

    if [[ "$abs_path" != /* ]]; then
        abs_path="$PWD/$abs_path"
    fi

    dir_name=$(dirname "$abs_path")
    base_name=$(basename "$abs_path")
    if norm_dir=$(cd "$dir_name" 2>/dev/null && pwd); then
        abs_path="$norm_dir/$base_name"
    fi

    rel_path="${abs_path#$BASE_DIR}"
    rel_path="${rel_path#/}"

    if [ -f "$BASE_DIR/$rel_path" ]; then
        formatted="$(format "$rel_path")"
        launch "$formatted"
        quit "true"
    else
        quit "false"
    fi
else
    init
    updateCache &

    selected=$(selectFiles)
    aerospace mode main

    if [ -n "$selected" ]; then
        updateRecentFiles "$selected"
        launch "$selected"
        quit "true"
    else
        quit "false"
    fi
fi

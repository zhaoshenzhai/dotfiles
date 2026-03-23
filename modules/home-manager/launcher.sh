#!/usr/bin/env bash

LOCKFILE="/tmp/launcher.lock"
CACHE_DIR="$HOME/.cache/launcher"
CACHE_FILE="$CACHE_DIR/files.txt"
RECENT_FILE="$CACHE_DIR/recent.txt"
BASE_DIR="$HOME/iCloud"

enforce_single_instance() {
    if [ -f "$LOCKFILE" ]; then
        local old_pid
        old_pid=$(cat "$LOCKFILE")
        if ps -p "$old_pid" > /dev/null; then
            exit 0
        fi
    fi
    echo $$ > "$LOCKFILE"
    trap 'rm -f "$LOCKFILE"' EXIT
}
setup_environment() {
    mkdir -p "$CACHE_DIR"
    touch "$RECENT_FILE"
    touch "$CACHE_FILE"
}
update_full_cache_bg() {
    (
        cd "$BASE_DIR" || exit
        fd --type f --hidden --exclude .git --exclude '*.old' . \
            "Documents" "Dotfiles" "Projects" | while read -r line; do

            if [[ "$line" =~ _attic/[0-9]{5}/metadata\.tex ]]; then
                continue
            fi

            if [[ "$line" =~ Projects/_attic/([0-9]{5})/([0-9]{5})\.tex ]]; then
                local id="${BASH_REMATCH[1]}"
                local kw_path="$BASE_DIR/Projects/_attic/$id/keywords"
                if [ -f "$kw_path" ]; then
                    local kw
                    kw=$(cat "$kw_path" 2>/dev/null)
                    echo -e "Projects/_attic/$id[$kw]\t$line"
                    continue
                fi
            elif [[ "$line" =~ Projects/_attic/([0-9]{5})/keywords ]]; then
                local id="${BASH_REMATCH[1]}"
                local kw_path="$BASE_DIR/Projects/_attic/$id/keywords"
                if [ -f "$kw_path" ]; then
                    local kw
                    kw=$(cat "$kw_path" 2>/dev/null)
                    echo -e "Projects/_attic/$id[$kw]/keywords\t$line"
                    continue
                fi
            fi

            echo -e "$line\t$line"
        done > "$CACHE_FILE.tmp" 2>/dev/null
        mv "$CACHE_FILE.tmp" "$CACHE_FILE"
    ) &
}
purge_recent_cache_bg() {
    (
        if [ ! -s "$RECENT_FILE" ]; then exit 0; fi

        while IFS=$'\t' read -r col1 col2; do
            if [[ -z "$col2" || ! -e "$BASE_DIR/$col2" ]]; then
                continue
            fi

            local valid=true

            if [[ "$col2" =~ Projects/_attic/([0-9]{5})/([0-9]{5})\.tex ]]; then
                local id="${BASH_REMATCH[1]}"
                local kw_path="$BASE_DIR/Projects/_attic/$id/keywords"
                if [ -f "$kw_path" ]; then
                    local kw
                    kw=$(cat "$kw_path" 2>/dev/null)
                    local expected="Projects/_attic/[$kw]"
                    if [[ "$col1" != "$expected" ]]; then
                        valid=false
                    fi
                fi
            elif [[ "$col2" =~ Projects/_attic/([0-9]{5})/keywords ]]; then
                local id="${BASH_REMATCH[1]}"
                local kw_path="$BASE_DIR/Projects/_attic/$id/keywords"
                if [ -f "$kw_path" ]; then
                    local kw
                    kw=$(cat "$kw_path" 2>/dev/null)
                    local expected="Projects/_attic/[$kw]/keywords"
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
}
show_fzf_ui() {
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
update_recent_post_selection() {
    local selected="$1"
    grep -vF -x "$selected" "$RECENT_FILE" > "$RECENT_FILE.tmp" 2>/dev/null || true
    echo "$selected" | cat - "$RECENT_FILE.tmp" | head -n 100 > "$RECENT_FILE"
    rm -f "$RECENT_FILE.tmp"
}
launch_target() {
    local selected="$1"
    local rel_path
    rel_path=$(echo "$selected" | cut -f2)
    local full_path="$BASE_DIR/$rel_path"

    if [[ "$full_path" == *.pdf ]]; then
        open -n -a Skim "$full_path" >/dev/null 2>&1 &
    else
        local nvim_path="/etc/profiles/per-user/$USER/bin/nvim"
        local hm_session="$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
        local exec_cmd="[ -f $hm_session ] && . $hm_session; export FROM_LAUNCHER=1; exec $nvim_path \"$full_path\""

        nohup alacritty -e sh -c "$exec_cmd" >/dev/null 2>&1 &
    fi

    aerospace mode main
    sleep 0.5
}

main() {
    enforce_single_instance
    setup_environment

    update_full_cache_bg
    purge_recent_cache_bg

    local selected_line=$(show_fzf_ui)

    if [ -n "$selected_line" ]; then
        update_recent_post_selection "$selected_line"
        launch_target "$selected_line"
    fi
}

main

#!/usr/bin/env bash

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
ATTIC_DIR="$HOME/iCloud/Projects/_attic"
TEMPLATE_FILE="$HOME/iCloud/Dotfiles/modules/scripts/LaTeXTemplate/files/attic.tex"

RL_PURPLE=$'\001\e[35m\002'
RL_CYAN=$'\001\e[36m\002'
RL_NC=$'\001\e[0m\002'

EXTRACT_IDS='while (/\\aref\{.*?\}\{([0-9]{5})\}/g) { print $1 }'
EXTRACT_LINES_AND_IDS='while (/\\aref\{.*?\}\{([0-9]{5})\}/g) { print "$.:$1" }'
extract_links() {
    perl -nle "$EXTRACT_IDS" "$1"
}
format_links() {
    sort -u | sed -E 's/^([0-9]{5})$/\\aref{\1}{\1}/' | paste -sd "," - | sed 's/,/, /g'
}

createNew() {
    local IN_KEYWORDS="$1"
    mkdir -p "$ATTIC_DIR"

    local ID
    while true; do
        ID=$(awk -v min=0 -v max=99999 'BEGIN{srand(); printf "%05d\n", int(min+rand()*(max-min+1))}')
        if [ ! -d "$ATTIC_DIR/$ID" ]; then break; fi
    done

    mkdir -p "$ATTIC_DIR/$ID"
    cp "$TEMPLATE_FILE" "$ATTIC_DIR/$ID/$ID.tex"

    if [[ "$IN_KEYWORDS" == "EMPTY_KEYWORDS" ]]; then
        KEYWORDS=""
        echo "Note $ID created automatically."
    elif [ -n "$IN_KEYWORDS" ]; then
        KEYWORDS="$IN_KEYWORDS"
        echo "Note $ID created automatically."
    else
        read -rep "${RL_PURPLE}Enter keywords for Note $ID (comma separated): ${RL_NC}" KEYWORDS
    fi

    echo "$KEYWORDS" | sed 's/,/, /g' | sed 's/  / /g' > "$ATTIC_DIR/$ID/$ID.key"
    generateMetadata "$ID"
    /etc/profiles/per-user/zhao/bin/launcher --update &
    (cd "$ATTIC_DIR/$ID" && latexmk -pdf "$ID.tex" > /dev/null 2>&1) &

    if [[ "$INTERACTIVE" == 1 ]]; then
        nvim_path="/etc/profiles/per-user/$USER/bin/nvim"
        hm_session="$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
        exec_cmd="[ -f $hm_session ] && . $hm_session; export FROM_LAUNCHER=1; exec $nvim_path \"$ATTIC_DIR/$ID/$ID.tex\""

        nohup alacritty -e sh -c "$exec_cmd" >/dev/null 2>&1 &
    fi
}
generateMetadata() {
    local ID=$1
    local DIR="$ATTIC_DIR/$ID"
    local FILE="$DIR/$ID.tex"

    if [ ! -f "$FILE" ]; then
        echo -e "${RED}Error: Note $ID does not exist.${NC}"
        return 1
    fi

    local MODIFIED=$(/usr/bin/stat -f "%Sm" -t "%Y/%m/%d" "$FILE")
    local KEYWORDS=$(cat "$DIR/$ID.key" 2>/dev/null)
    local REFS=$(extract_links "$FILE" | format_links)
    local REF_IN=$(for f in "$ATTIC_DIR"/*/*.tex; do [ "$f" != "$FILE" ] && extract_links "$f" | grep -q "^$ID$" && basename "$f" .tex; done | format_links)

    local TEMP_META="$DIR/metadata.tmp"
    cat <<EOF > "$TEMP_META"
\begin{flushleft}
    \color{gray}\footnotesize\ttfamily
    Last modified: $MODIFIED \\\\
    Keywords: [$KEYWORDS] \\\\
    References: [$REFS] \\\\
    Referenced in: [$REF_IN]
\end{flushleft}
EOF

    if cmp -s "$TEMP_META" "$DIR/$ID.dat" 2>/dev/null; then
        rm "$TEMP_META"
        return 1
    else
        mv "$TEMP_META" "$DIR/$ID.dat"
        echo -e "${GREEN}Metadata updated for $ID.${NC}"
        return 0
    fi
}
updateMetadata() {
    local ID=$1
    local FILE="$ATTIC_DIR/$ID/$ID.tex"
    local META_FILE="$ATTIC_DIR/$ID/$ID.dat"

    if [ ! -f "$FILE" ]; then
        return
    fi

    is_compiling() {
        pgrep -f "latexmk.*$1\.tex" > /dev/null
    }

    local OLD_REFS=""
    if [ -f "$META_FILE" ]; then
        OLD_REFS=$(grep "References:" "$META_FILE" 2>/dev/null | grep -E -o '[0-9]{5}')
    fi

    if generateMetadata "$ID" > /dev/null 2>&1; then
        if ! is_compiling "$ID"; then
            # (cd "$ATTIC_DIR/$ID" && latexmk -pdf "$ID.tex" > /dev/null 2>&1) &
        fi
    fi

    local NEW_REFS=$(grep -E -o '\\aref\{[^}]*\}\{[0-9]{5}\}' "$FILE" 2>/dev/null | sed -E 's/.*\{([0-9]{5})\}/\1/')
    local ALL_REFS=$(echo "$OLD_REFS $NEW_REFS" | grep -E -o '[0-9]{5}' | sort -u)

    for ref_id in $ALL_REFS; do
        if [ -n "$ref_id" ] && [ -d "$ATTIC_DIR/$ref_id" ]; then
            if generateMetadata "$ref_id" > /dev/null 2>&1; then
                if ! is_compiling "$ref_id"; then
                    # (cd "$ATTIC_DIR/$ref_id" && latexmk -pdf "$ref_id.tex" > /dev/null 2>&1) &
                fi
            fi
        fi
    done
}
clean() {
    echo -e "${BLUE}Cleaning up LaTeX auxiliary files...${NC}"
    find "$ATTIC_DIR" -type f \( \
        -name "*.aux" -o \
        -name "*.bbl" -o \
        -name "*.bcf" -o \
        -name "*bcf-SAVE-ERROR" -o \
        -name "*.blg" -o \
        -name "*.fdb_latexmk" -o \
        -name "*.fls" -o \
        -name "*.log" -o \
        -name "*.run.xml" -o \
        -name "*.synctex.gz" -o \
        -name "*.synctex(busy)" \
    \) -delete
    echo -e "${GREEN}Cleanup complete.${NC}"
}
auditNotes() {
    echo -e "${BLUE}Verifying links, metadata bijection, and scanning for TODOs...${NC}"
    local BROKEN=0
    local TODOS=0
    local DESYNC=0

    while read -r rel_file; do
        local file="$ATTIC_DIR/$rel_file"
        local id=$(basename "$file" .tex)

        if [[ ! "$id" =~ ^[0-9]{5}$ ]]; then
            continue
        fi

        while read -r match; do
            local line_no="${match%%:*}"
            local target_id="${match#*:}"

            local T_FILE="$ATTIC_DIR/$target_id/$target_id.tex"
            local P_FILE="$ATTIC_DIR/$target_id/$target_id.pdf"
            local ERR=""
            [[ ! -f "$T_FILE" ]] && ERR="TEX"
            if [[ ! -f "$P_FILE" ]]; then [[ -n "$ERR" ]] && ERR="$ERR & "; ERR="${ERR}PDF"; fi

            if [[ -n "$ERR" ]]; then
                echo -e "${RED}[MISSING $ERR]${NC} ID $target_id referenced in $id:$line_no"
                ((BROKEN++))
            fi
        done < <(perl -nle "$EXTRACT_LINES_AND_IDS" "$file" 2>/dev/null)

        while read -r todo_match; do
            local line_no="${todo_match%%:*}"
            local text="${todo_match#*:}"

            text="$(echo "$text" | sed 's/^[[:space:]]*//')"
            echo -e "${YELLOW}[TODO]${NC} $id:$line_no -> $text"
            ((TODOS++))
        done < <(grep -n "TODO" "$file" 2>/dev/null)

        local meta="$ATTIC_DIR/$id/$id.dat"

        local REFS=$(extract_links "$file" | format_links)
        local REF_IN=$(for f in "$ATTIC_DIR"/*/*.tex; do [ "$f" != "$file" ] && extract_links "$f" | grep -q "^$id$" && basename "$f" .tex; done | format_links)

        local EXPECTED_REFS="References: [$REFS]"
        local EXPECTED_REF_IN="Referenced in: [$REF_IN]"

        local ACTUAL_REFS=$(grep "References:" "$meta" 2>/dev/null | sed 's/^[[:space:]]*//' | sed 's/ \\\\$//')
        local ACTUAL_REF_IN=$(grep "Referenced in:" "$meta" 2>/dev/null | sed 's/^[[:space:]]*//' | sed 's/ \\\\$//')

        if [[ "$EXPECTED_REFS" != "$ACTUAL_REFS" ]] || [[ "$EXPECTED_REF_IN" != "$ACTUAL_REF_IN" ]]; then
            echo -e "${PURPLE}[DESYNC]${NC} Metadata for $id breaks bijection (links out of sync)."
            ((DESYNC++))
        fi
    done < <(cd "$ATTIC_DIR" && fd -e tex)

    echo "----------------------------------------"
    if [ $BROKEN -eq 0 ]; then
        echo -e "${GREEN}Links: Valid!${NC}"
    else
        echo -e "${RED}Links: Found $BROKEN broken link(s).${NC}"
    fi

    if [ $DESYNC -eq 0 ]; then
        echo -e "${GREEN}Metadata: Valid!${NC}"
    else
        echo -e "${PURPLE}Metadata: $DESYNC note(s) have desynchronized metadata. Run 'rebuild all' (r) to fix.${NC}"
    fi

    if [ $TODOS -eq 0 ]; then
        echo -e "${GREEN}TODOs: None found!${NC}"
    else
        echo -e "${YELLOW}TODOs: You have $TODOS pending TODO(s).${NC}"
    fi
}
rebuildAll() {
    echo -e "${BLUE}Refreshing metadata and recompiling all notes. This may take a moment...${NC}"
    local dirs=("$ATTIC_DIR"/[0-9][0-9][0-9][0-9][0-9]/)

    if [ ! -d "${dirs[0]}" ]; then
        echo -e "${GREEN}No notes found to rebuild.${NC}"
        return
    fi

    local total=${#dirs[@]}
    local count=0

    for dir in "${dirs[@]}"; do
        ((count++))
        local id=$(basename "$dir")

        echo -ne "\033[2K\r${YELLOW}Processing note $id ($count/$total)...${NC}"

        generateMetadata "$id" > /dev/null
        (cd "$dir" && latexmk -pdf "$id.tex" > /dev/null 2>&1)
    done

    echo -e "\033[2K\r${GREEN}Successfully rebuilt $total note(s) and their metadata.${NC}"
}

EXIT() {
    echo ""
    read -n 1 -ep "${RL_CYAN}Press [Y] to return, exiting otherwise... ${RL_NC}" repeat
    if [[ "$repeat" == "Y" ]] || [[ "$repeat" == "y" ]] || [[ -z "$repeat" ]]; then
        clear
        exec "$0"
    fi
    aerospace close --quit-if-last-window 2>/dev/null || exit 0
}
INTERACTIVE_MENU() {
    local valid=""
    while [[ -z $valid ]]; do
        echo -e "${CYAN}Attic operations:${NC}"
        echo -e "    ${CYAN}(n): New note${NC}"
        echo -e "    ${CYAN}(a): Audit notes${NC}"
        echo -e "    ${CYAN}(c): Clean LaTeX files${NC}"
        echo -e "    ${CYAN}(r): Rebuild all metadata & PDFs${NC}"

        read -n 1 -ep "${RL_CYAN}Select operation: [n, a, c, r] ${RL_NC}" cmdNum

        if [[ "$cmdNum" == "q" ]]; then
            aerospace close --quit-if-last-window 2>/dev/null || exit 0
        elif [[ "$cmdNum" =~ ^[nacr]$ ]]; then
            valid=1
        else
            clear
        fi
    done

    echo ""

    case $cmdNum in
        "n") createNew ;;
        "a") auditNotes ;;
        "c") clean ;;
        "r") rebuildAll ;;
    esac

    EXIT
}
MAIN() {
    if [[ $# -gt 0 ]]; then
        INTERACTIVE=0
        while getopts "ek:nu:m:acr" opt; do
            case $opt in
                e) createNew "EMPTY_KEYWORDS"; exit 0 ;;
                k) createNew "$OPTARG"; exit 0 ;;
                n) createNew; exit 0 ;;
                m) generateMetadata "$OPTARG"; exit 0 ;;
                u) updateMetadata "$OPTARG"; exit 0 ;;
                a) auditNotes; exit 0 ;;
                c) clean; exit 0 ;;
                r) rebuildAll; exit 0 ;;
                *) echo "Usage: attic [-n] [-e] [-k keywords] [-m ID] [-u ID] [-a] [-c] [-r]"; exit 1 ;;
            esac
        done
    else
        INTERACTIVE=1
        INTERACTIVE_MENU
    fi
}

MAIN

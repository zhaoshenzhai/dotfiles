#!/usr/bin/env bash

ATTIC_DIR="$HOME/iCloud/Projects/_attic"
TEMPLATE_FILE="$HOME/iCloud/Dotfiles/modules/scripts/LaTeXTemplate/files/attic.tex"

create_new() {
    mkdir -p "$ATTIC_DIR"

    local ID
    while true; do
        ID=$(awk -v min=0 -v max=99999 'BEGIN{srand(); printf "%05d\n", int(min+rand()*(max-min+1))}')
        if [ ! -d "$ATTIC_DIR/$ID" ]; then break; fi
    done

    mkdir -p "$ATTIC_DIR/$ID"
    cp "$TEMPLATE_FILE" "$ATTIC_DIR/$ID/$ID.tex"

    read -ep "$(echo -e ${PURPLE}"Enter keywords for Note $ID (comma separated): ${NC}")" KEYWORDS
    echo "$KEYWORDS" | sed 's/,/, /g' | sed 's/  / /g' > "$ATTIC_DIR/$ID/keywords"

    generate_metadata "$ID"

    echo -e "${BLUE}Compiling initial PDF...${NC}"
    cd "$ATTIC_DIR/$ID" && latexmk -pdf "$ID.tex" > /dev/null 2>&1

    if [[ "$INTERACTIVE" == 1 ]]; then
        nvim "$ID.tex"
    fi
}
generate_metadata() {
    local ID=$1
    local DIR="$ATTIC_DIR/$ID"
    local FILE="$DIR/$ID.tex"

    if [ ! -f "$FILE" ]; then
        echo -e "${RED}Error: Note $ID does not exist.${NC}"
        return
    fi

    local CREATED=$(/usr/bin/stat -f "%SB" -t "%Y/%m/%d" "$FILE")
    local MODIFIED=$(/usr/bin/stat -f "%Sm" -t "%Y/%m/%d" "$FILE")

    local KEYWORDS=$(cat "$DIR/keywords" 2>/dev/null)

    local REFS=$(grep -o "\\aref{[^}]*}{[0-9]\{5\}}" "$FILE" 2>/dev/null | sed 's/.*{\([0-9]\{5\}\)}/\1/' | sort -u | paste -sd "," - | sed 's/,/, /g')
    local REF_IN=$(grep -rl "\\aref{[^}]*}{$ID}" "$ATTIC_DIR" --include="*.tex" 2>/dev/null | grep -v "$FILE" | xargs -I {} basename {} .tex | sort -u | paste -sd "," - | sed 's/,/, /g')

    cat <<EOF > "$DIR/metadata.tex"
\begin{flushleft}
    \color{gray}\footnotesize\ttfamily
    Created: $CREATED \\\\
    Last modified: $MODIFIED \\\\
    Keywords: [$KEYWORDS] \\\\
    References: [$REFS] \\\\
    Referenced in: [$REF_IN]
\end{flushleft}
EOF
    echo -e "${GREEN}Metadata updated for $ID.${NC}"
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
audit_notes() {
    echo -e "${BLUE}Verifying internal links and scanning for TODOs...${NC}"
    local BROKEN=0
    local TODOS=0

    while read -r rel_file; do
        local file="$ATTIC_DIR/$rel_file"

        while read -r match; do
            local line_no="${match%%:*}"

            if [[ "$match" =~ \{([0-9]{5})\} ]]; then
                local id="${BASH_REMATCH[1]}"
                local T_FILE="$ATTIC_DIR/$id/$id.tex"
                local P_FILE="$ATTIC_DIR/$id/$id.pdf"
                local ERR=""

                [[ ! -f "$T_FILE" ]] && ERR="TEX"
                if [[ ! -f "$P_FILE" ]]; then
                    [[ -n "$ERR" ]] && ERR="$ERR & "
                    ERR="${ERR}PDF"
                fi

                if [[ -n "$ERR" ]]; then
                    echo -e "${RED}[MISSING $ERR]${NC} ID $id in $(basename "$file"):$line_no"
                    ((BROKEN++))
                fi
            fi
        done < <(grep -E -n -o '\\aref\{[^}]*\}\{[0-9]{5}\}' "$file" 2>/dev/null)

        while read -r todo_match; do
            local line_no="${todo_match%%:*}"
            local text="${todo_match#*:}"

            text="$(echo "$text" | sed 's/^[[:space:]]*//')"
            echo -e "${YELLOW}[TODO]${NC} $(basename "$file"):$line_no -> $text"
            ((TODOS++))
        done < <(grep -n "TODO" "$file" 2>/dev/null)

    done < <(cd "$ATTIC_DIR" && fd -e tex)

    echo "----------------------------------------"
    if [ $BROKEN -eq 0 ]; then
        echo -e "${GREEN}Links: All internal links are valid.${NC}"
    else
        echo -e "${RED}Links: Found $BROKEN broken link(s).${NC}"
    fi

    if [ $TODOS -eq 0 ]; then
        echo -e "${GREEN}TODOs: None found!${NC}"
    else
        echo -e "${YELLOW}TODOs: You have $TODOS pending TODO(s).${NC}"
    fi
}
rebuild_all() {
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

        generate_metadata "$id" > /dev/null
        (cd "$dir" && latexmk -pdf "$id.tex" > /dev/null 2>&1)
    done

    echo -e "\033[2K\r${GREEN}Successfully rebuilt $total note(s) and their metadata.${NC}"
}

EXIT() {
    echo ""
    read -n 1 -ep "$(echo -e ${CYAN}"Press [Y] to return, exiting otherwise...${NC} ")" repeat
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
        echo -e "    ${CYAN}(a): Audit notes & TODOs${NC}"
        echo -e "    ${CYAN}(c): Clean LaTeX files${NC}"
        echo -e "    ${CYAN}(m): Manually generate metadata${NC}"
        echo -e "    ${CYAN}(r): Rebuild all metadata & PDFs${NC}"

        read -n 1 -ep "$(echo -e "${CYAN}Select operation: [n, a, c, m, r]${NC} ")" cmdNum

        if [[ "$cmdNum" == "q" ]]; then
            aerospace close --quit-if-last-window 2>/dev/null || exit 0
        elif [[ "$cmdNum" =~ ^[nacmr]$ ]]; then
            valid=1
        else
            clear
        fi
    done

    echo ""

    case $cmdNum in
        "n") create_new ;;
        "a") audit_notes ;;
        "c") clean ;;
        "m")
            read -ep "$(echo -e ${PURPLE}"Enter Note ID: ${NC}")" targetID
            if [[ -n "$targetID" ]]; then
                generate_metadata "$targetID"
            fi
        ;;
        "r") rebuild_all ;;
    esac

    EXIT
}

if [[ $# -gt 0 ]]; then
    INTERACTIVE=0
    while getopts "nm:acr" opt; do
        case $opt in
            n) create_new; exit 0 ;;
            m) generate_metadata "$OPTARG"; exit 0 ;;
            a) audit_notes; exit 0 ;;
            c) clean; exit 0 ;;
            r) rebuild_all; exit 0 ;;
            *) echo "Usage: attic [-n] [-m ID] [-a] [-c] [-r]"; exit 1 ;;
        esac
    done
else
    INTERACTIVE=1
    INTERACTIVE_MENU
fi

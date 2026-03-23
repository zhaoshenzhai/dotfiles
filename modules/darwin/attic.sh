#!/usr/bin/env bash

ATTIC_DIR="$HOME/iCloud/Projects/_attic"
TEMPLATE_FILE="$HOME/iCloud/Dotfiles/modules/darwin/LaTeXTemplate/files/attic.tex"

create_new() {
    mkdir -p "$ATTIC_DIR"

    local ID
    while true; do
        ID=$(awk -v min=0 -v max=99999 'BEGIN{srand(); printf "%05d\n", int(min+rand()*(max-min+1))}')
        if [ ! -d "$ATTIC_DIR/$ID" ]; then break; fi
    done

    mkdir -p "$ATTIC_DIR/$ID"
    cp "$TEMPLATE_FILE" "$ATTIC_DIR/$ID/$ID.tex"

    echo -n "Enter keywords for Note $ID (comma separated): " && read -r KEYWORDS
    echo "$KEYWORDS" | sed 's/,/, /g' | sed 's/  / /g' > "$ATTIC_DIR/$ID/keywords"

    generate_metadata "$ID"
    cd "$ATTIC_DIR/$ID" && latexmk -pdf "$ID.tex" > /dev/null 2>&1
}

generate_metadata() {
    local ID=$1
    local DIR="$ATTIC_DIR/$ID"
    local FILE="$DIR/$ID.tex"

    if [ ! -f "$FILE" ]; then
        echo -e "\033[0;31mError: Note $ID does not exist.\033[0m"
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
    echo -e "\033[0;32mMetadata updated for $ID.\033[0m"
}

clean() {
    echo -e "\033[0;34mCleaning up...\033[0m"
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
    echo -e "\033[0;32mCleanup complete.\033[0m"
}

audit_notes() {
    echo -e "\033[0;34mVerifying internal links...\033[0m"
    local BROKEN=0

    fd -e tex . "$ATTIC_DIR" | while read -r file; do
        grep -n "\\aref{" "$file" | while read -r line; do
            local id=$(echo "$line" | sed -n 's/.*{\([0-9]\{5\}\)}/\1/p')

            if [[ -n "$id" ]]; then
                local T_FILE="$ATTIC_DIR/$id/$id.tex"
                local P_FILE="$ATTIC_DIR/$id/$id.pdf"
                local ERR=""

                [[ ! -f "$T_FILE" ]] && ERR="TEX"
                if [[ ! -f "$P_FILE" ]]; then
                    [[ -n "$ERR" ]] && ERR="$ERR & "
                    ERR="${ERR}PDF"
                fi

                if [[ -n "$ERR" ]]; then
                    echo -e "\033[0;31m[MISSING $ERR]\033[0m ID $id in $file:$(echo "$line" | cut -d: -f1)"
                    ((BROKEN++))
                fi
            fi
        done
    done

    if [ $BROKEN -eq 0 ]; then
        echo -e "\033[0;32mAll internal links are valid.\033[0m"
    else
        echo -e "\033[0;33mFound $BROKEN broken link(s).\033[0m"
    fi

    clean
}

while getopts "nm:ac" opt; do
  case $opt in
    n) create_new; exit 0 ;;
    m) generate_metadata "$OPTARG"; exit 0 ;;
    a) audit_notes; exit 0 ;;
    c) clean; exit 0 ;;
    *) echo "Usage: attic -n | -m ID | -a"; exit 1 ;;
  esac
done

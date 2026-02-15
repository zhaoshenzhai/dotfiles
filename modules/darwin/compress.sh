#!/usr/bin/env bash

for file in "$@"; do
    name=$(basename -- "$file")
    ext="${name##*.}"
    if [[ -f "$file" ]] && [[ "$ext" == "pdf" ]]; then
        echo -ne "${YELLOW}Compressing: $file${NC}\r"
        gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.5 -dPDFSETTINGS=/printer -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$file.tmp" "$file"

        oldSize=$(du "$file" | awk '{print $1}')
        newSize=$(du "$file.tmp" | awk '{print $1}')

        echo -ne "\033[0K\r"

        if [[ $newSize -ge $oldSize ]]; then
            rm "$file.tmp"
            echo -e "${CYAN}[No changes] $file${NC}"
        else
            oldSizeHuman=$(du -h "$file" | awk '{print $1}')
            newSizeHuman=$(du -h "$file.tmp" | awk '{print $1}')

            echo -e "${GREEN}[$oldSizeHuman  ->  $newSizeHuman] $file${NC}"
            cp "$file" "bak_$file"
            mv "$file.tmp" "$file"
        fi
    fi
done

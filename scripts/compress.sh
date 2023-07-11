#!/bin/bash

for file in "$@"; do
    echo -ne "${YELLOW}Compressing: $file${NC}\r"
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.5 -dPDFSETTINGS=/printer -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$file.tmp" "$file"
    
    oldSize=$(du "$file" | awk '{print $1}')
    newSize=$(du "$file.tmp" | awk '{print $1}')
    
    echo -ne "\033[0K\r"

    if [[ $newSize -ge $oldSize ]]; then
        cp "$file" "$file.tmp"
        echo -e "${CYAN}[No changes] $file${NC}"
    else
        oldSizeHuman=$(du -h "$file" | awk '{print $1}')
        newSizeHuman=$(du -h "$file.tmp" | awk '{print $1}')
       
        echo -e "${GREEN}[$oldSizeHuman  ->  $newSizeHuman] $file${NC}"
    fi

    mv "$file" "$file.bak"
    mv "$file.tmp" "$file"
done

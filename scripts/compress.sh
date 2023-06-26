#!/bin/bash

for file in "$@"; do
    echo -ne "${YELLOW}Compressing: $file${NC}\r"
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.5 -dPDFSETTINGS=/printer -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$file.compressed" "$file"
    
    oldSize=$(du "$file" | awk '{print $1}')
    newSize=$(du "$file.compressed" | awk '{print $1}')
    
    echo -ne "\033[0K\r"

    if [[ $newSize -ge $oldSize ]]; then
        cp "$file" "$file.compressed"
        echo -e "${CYAN}[No changes] $file${NC}"
    else
        oldSizeHuman=$(du -h "$file" | awk '{print $1}')
        newSizeHuman=$(du -h "$file.compressed" | awk '{print $1}')
       
        echo -e "${GREEN}[$oldSizeHuman  ->  $newSizeHuman] $file${NC}"
    fi
done

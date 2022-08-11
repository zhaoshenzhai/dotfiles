#!/bin/bash

YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

repeat="Y"
while [[ "$repeat" == "Y" ]]; do
    if [[ $PWD == "/home/zhao/Dropbox/obsidian-mathlinks/src" ]]; then
        npm run dev
        cp ../main.js ~/TestVault/.obsidian/plugins/obsidian-mathlinks/main.js
        cp ../manifest.json ~/TestVault/.obsidian/plugins/obsidian-mathlinks/manifest.json
    else
        tsc -noEmit -skipLibCheck && node esbuild.config.mjs production

        out=$(echo $PWD/$1 | sed 's/\.ts/\.js/g')
        if [[ -f $out ]]; then
            echo ""
            echo -e "${CYAN}----  Starts here  ----${NC}"
            node $out
            echo ""
        fi
    fi

    echo -e "${GREEN}DONE${NC}"
    echo ""

    read -n 1 -ep "$(echo -e ${CYAN}"Press [Y] to return, exiting otherwise...${NC} ")" repeat
    if [[ -z "$repeat" ]]; then
        repeat="Y"
    fi
    if [[ "$repeat" == "Y" ]]; then
        clear
    else
        exit
    fi
done

#!/bin/bash

repeat="Y"
while [[ "$repeat" == "Y" ]]; do
    if [[ $PWD == "/home/zhao/Dropbox/MathLinks/src" ]]; then
        npm run dev
        cp ../main.js ~/Downloads/Test_Vault/.obsidian/plugins/mathlinks/main.js
        cp ../manifest.json ~/Downloads/Test_Vault/.obsidian/plugins/mathlinks/manifest.json
        # cp ../main.js $MATHWIKI_DIR/.obsidian/plugins/mathlinks/main.js
        # cp ../manifest.json $MATHWIKI_DIR/.obsidian/plugins/mathlinks/manifest.json
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

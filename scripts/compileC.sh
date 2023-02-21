#!/bin/bash

YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

output=$(echo $2 | sed 's/\.c//g' | sed 's/$/\.out/g')

repeat="Y"
Run() {
    while [[ "$repeat" == "Y" ]]; do
        ./$output

        echo ""
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
}

while getopts 'c:r:' OPTION; do
    case "$OPTION" in
        c)
            gcc $OPTARG -o $output
        ;;
        r)
            if [[ -z $(echo $(ls) | grep ".out") ]]; then
                gcc $OPTARG -o $output
            fi
        ;;
    esac

    Run
done
shift "$(($OPTIND -1))"

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
    output=$(echo $1 | sed 's/\.c//g')
    gcc $1 -o $output
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

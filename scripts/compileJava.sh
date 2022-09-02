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
    cd $(echo $1 | sed 's/\/src.*$//g')

    find -name "*.java" > src.txt
    javac -d build @src.txt

    mainPath=$(grep -lr "public static void main(String\[\] args)" * | sed 's/src\///g' | sed 's/\.java$//g')
    cd build
    java $mainPath

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

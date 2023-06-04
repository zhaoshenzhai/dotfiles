#!/bin/bash

repeat="Y"
while [[ "$repeat" == "Y" ]]; do
    mcs -out:$1/Program.exe $1/Program.cs
    mono $1/Program.exe

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

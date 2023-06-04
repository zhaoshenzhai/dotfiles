#!/bin/bash

repeat="Y"
output=$(echo "$2" | sed 's/.c$//g')

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
            gcc -o $output $OPTARG
        ;;
        r)
            if [[ -z $(echo $(ls) | grep ".out") ]]; then
                gcc -o $output $OPTARG
            fi
        ;;
    esac

    Run
done
shift "$(($OPTIND -1))"

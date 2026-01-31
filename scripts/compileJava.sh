#!/bin/bash

repeat="Y"
Run() {
    while [[ "$repeat" == "Y" ]]; do
        mainPath=$(grep -lr "public static void main(String\[\] args)" * | sed 's/src\///g' | sed 's/\.java$//g' | sed 's/\//./g')
        cd build
        java $mainPath
        cd ..

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
            cd $(echo $OPTARG | sed 's/\/src.*$//g')
            find -name "*.java" > src.txt
            javac -d build @src.txt
            Run
        ;;
        r)
            cd $(echo $OPTARG | sed 's/\/src.*$//g')

            if [[ -z $(echo $(ls) | grep "build") ]]; then
                find -name "*.java" > src.txt
                javac -d build @src.txt
            fi

            Run
        ;;
    esac
done
shift "$(($OPTIND -1))"

#!/bin/bash

projectName=
mainName=

HELP() {
    echo -e "Usage: ./newC.sh [-p projectName] [-n mainName|projectName]"
}

while [[ ! -z $1 ]]; do
    case $1 in
        -h|--help)
            HELP
            exit 0
            ;;
        -p)
            projectName=$2
            mainName=$2
            ;;
        -n)
            mainName=$2
            ;;
    esac
    shift
    shift
done

if [[ -z $projectName ]]; then
    echo -e "${RED}Error: Expected [-p] flag.${NC}"
    HELP
    exit 1
fi

mkdir $projectName
cd $projectName

cp $DOTFILES_DIR/files/C_template.c $mainName.c

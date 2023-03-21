#!/bin/bash

YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

name=

HELP() {
    echo -e "Usage: ./newC.sh [-n name]"
}

while [[ ! -z $1 ]]; do
    case $1 in
        -h|--help)
            HELP
            exit 0
            ;;
        -n)
            name=$2
            ;;
    esac
    shift
    shift
done

if [[ -z $name ]]; then
    echo -e "${RED}Error: Expected [-n] flag.${NC}"
    HELP
    exit 1
fi

cp $DOTFILES_DIR/files/C_template.c $name.c

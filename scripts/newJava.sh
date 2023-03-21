#!/bin/bash

YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

projectName=
mainName="Main"

HELP() {
    echo -e "Usage: ./newJava.sh [-p projectName] [-n mainName|\"Main\"]"
}

while [[ ! -z $1 ]]; do
    case $1 in
        -h|--help)
            HELP
            exit 0
            ;;
        -p)
            projectName=$2
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
mkdir "src"
cd "src"

cp $DOTFILES_DIR/files/Java_template.java $mainName.java
sed -i "s/NAME/$mainName/g" $mainName.java

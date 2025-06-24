#!/bin/bash

filesPath=$DOTFILES_DIR/files/LaTeXBeamerTemplate
name=
title=

# Help
HELP() {
    echo -e "Usage: ./newLaTeXBeamer.sh [-n name]"
}

# Input
while [[ ! -z $1 ]]; do
    case $1 in
        -h|--help)
            HELP
            exit 0
            ;;
        -n)
            name=$2
            title=$(echo $name | sed 's/_/ /g')
    esac
    shift
    shift
done

# Validate
if [[ -z $name ]]; then
    echo -e "${RED}Error: Expected [-n] flag.${NC}"
    HELP
    exit 1
fi

mkdir "$name"
cd "$name"

cp -r $filesPath/* .
mv file.tex "$name.tex"
sed -i 's/NAME/'"$title"'/g' "$name.tex"

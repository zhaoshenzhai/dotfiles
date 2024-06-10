#!/bin/bash

filesPath=$DOTFILES_DIR/files/LaTeXTemplate
name=

# Help
HELP() {
    echo -e "Usage: ./newLaTeX.sh [-n name]"
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

mkdir $name
cd $name

cp $filesPath/* .
mv file.tex $name.tex
sed -i 's/NAME/'"$name"'/g' $name.tex

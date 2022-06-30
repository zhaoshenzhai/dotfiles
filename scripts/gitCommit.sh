#!/bin/bash

YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

while [ ! -z "$1" ]; do
    case "$1" in
        --prompt|-p)
            echo -e "${CYAN}Repositories:${NC}"
            echo -e "${CYAN}    (1): MathWiki${NC}"
            echo -e "${CYAN}    (2): dotfiles${NC}"
            printf "\n"

            read -n 1 -ep "$(echo -e ${CYAN}"Select repository: [1,2]${NC} ")" repo
            if [ "$repo" == "q" ]; then
                exit
            fi
            while [ ! "$repo" == "1" ] && [ ! "$repo" == "2" ]; do
                read -n 1 -ep "$(echo -e ${CYAN}"Select repository: [1,2]${NC} ")" repo
                if [ "$repo" == "q" ]; then
                    exit
                fi
            done

            case $repo in
                "1")
                    path="$HOME/MathWiki/"
                ;;
                "2")
                    path="$HOME/.config/"
                ;;
            esac

            cd "$path"
        ;;
        --MathWiki|-m)
            repo="1"
            cd "$HOME/MathWiki/"
    esac
shift
done

printf "\n"
git status
printf "\n"

if [[ "$repo" == "1" ]]; then
    read -n 1 -ep "$(echo -e ${PURPLE}"Show diff? [Y/a/n]${NC} ")" choice
    if [ -z "$choice" ] || [ "$choice" == "Y" ]; then
        printf "\n"
        git diff "Notes/*"
    elif [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
        printf "\n"
        git diff
    elif [ "$choice" == "q" ]; then
        exit
    fi
else
    read -n 1 -ep "$(echo -e ${PURPLE}"Show diff? [Y/n]${NC} ")" choice
    if [ -z "$choice" ] || [ "$choice" == "Y" ]; then
        printf "\n"
        git diff
    elif [ "$choice" == "q" ]; then
        exit
    fi
fi

printf "\n"

read -n 1 -ep "$(echo -e ${PURPLE}"Commit? [Y/n]${NC} ")" choice
if [ -z "$choice" ] || [ "$choice" == "Y" ]; then
    if [[ "$repo" == "1" ]]; then
        source ~/MathWiki/.scripts/stats.sh -u
        source ~/MathWiki/.scripts/stats.sh -r

        templatesInsertLine=$(grep -n "#### Templates" ~/.config/nvim/UltiSnips/markdown.snippets | sed 's/:.*$//g')
        sed -i 's|\[templatesInsert\]:.*$|\[templatesInsert\]: https://github.com/zhaoshenzhai/dotfiles/blob/master/nvim/UltiSnips/markdown.snippets#L'"$templatesInsertLine"'|g' README.md

        tikzInsertLine=$(grep -n "newTikZ.sh" ~/.config/nvim/config/MathWiki.vim | sed 's/:.*$//g')
        sed -i 's|\[tikzInsert\]:.*$|\[tikzInsert\]: https://github.com/zhaoshenzhai/dotfiles/blob/master/nvim/config/MathWiki.vim#L'"$tikzInsertLine"'|g' README.md

        pdfLaTeXExecuteLine=$(grep -n "pdflatex -shell-escape image.tex" ~/.config/nvim/config/MathWiki.vim | sed 's/:.*$//g')
        sed -i 's|\[pdfLaTeXExecute\]:.*$|\[pdfLaTeXExecute\]: https://github.com/zhaoshenzhai/dotfiles/blob/master/nvim/config/MathWiki.vim#L'"$pdfLaTeXExecuteLine"'|g' README.md

        autoAliasLine=$(grep -n "Math()" ~/MathWiki/.scripts/mathLinks.sh | sed 's/:.*$//g')
        sed -i 's|\[standardAlias\]:.*$|\[standardAlias\]: https://github.com/zhaoshenzhai/MathWiki/blob/master/.scripts/mathLinks.sh#L'"$autoAliasLine"'|g' README.md
    fi

    git add .

    printf "\n"
    git status
    printf "\n"

    read -ep "$(echo -e ${PURPLE}"Remove files? [N/(string)]${NC} ")" choice
    while [[ ! -z $choice ]]; do
        git restore --staged "$choice"

        printf "\n"
        git status
        printf "\n"

        read -ep "$(echo -e ${PURPLE}"Remove files? [N/(string)]${NC} ")" choice
    done

    printf "\n"
    read -ep "$(echo -e ${PURPLE}"Message:${NC} ")" msg
    while [ -z "$msg" ]; do
        read -ep "$(echo -e ${PURPLE}"Message:${NC} ")" msg
    done
    printf "\n"

    git commit -m "$msg"
    printf "\n"
    git push
else
    exit
fi

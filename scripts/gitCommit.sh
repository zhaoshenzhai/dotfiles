#!/bin/bash

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

while [ ! -z "$1" ]; do
    case "$1" in
        --prompt|-p)
            echo -e "${CYAN}Repositories:${NC}"
            echo -e "${CYAN}    (1): MathWiki${NC}"
            echo -e "${CYAN}    (2): dotfiles${NC}"
            printf "\n"

            read -n 1 -ep "$(echo -e ${CYAN}"Select repository: [1,2] "${NC})" repo
            while [ ! "$repo" == "1" ] && [ ! "$repo" == "2" ]; do
                read -n 1 -ep "$(echo -e ${CYAN}"Select repository: [1,2] "${NC})" repo
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
    esac
    case "$1" in
        --MathWiki|-m)
            repo="1"
            cd "$HOME/MathWiki/"
    esac
shift
done

printf "\n"
git status
printf "\n"

read -n 1 -ep "$(echo -e ${CYAN}"Show diff? [Y/n] "${NC})" choice
if [ -z "$choice" ] || [ "$choice" == "Y" ]; then
    printf "\n"
    git diff
fi

printf "\n"

read -n 1 -ep "$(echo -e ${CYAN}"Commit? [Y/n] "${NC})" choice
if [ -z "$choice" ] || [ "$choice" == "Y" ]; then
    if [[ "$repo" == "1" ]]; then
        cd ~/MathWiki/
        source ~/MathWiki/.scripts/stats.sh -u

        templatesInsertLine=$(grep -n "#### Templates" ~/.config/nvim/UltiSnips/vimwiki.snippets | sed 's/:.*$//g')
        sed -i 's|\[templatesInsert\]:.*$|\[templatesInsert\]: https://github.com/zhaoshenzhai/dotfiles/blob/master/nvim/UltiSnips/vimwiki.snippets#L'"$templatesInsertLine"'|g' README.md
        tikzInsertLine=$(grep -n "pdflatex -shell-escape image.tex" ~/.config/nvim/config/MathWiki.vim | sed 's/:.*$//g')
        pdfLaTeXExecuteLine=$(grep -n "newTikZ.sh" ~/.config/nvim/config/MathWiki.vim | sed 's/:.*$//g')
        sed -i 's|\[pdfLaTeXExecute\]:.*$|\[pdfLaTeXExecute\]: https://github.com/zhaoshenzhai/dotfiles/blob/master/nvim/config/MathWiki.vim#L'"$pdfLaTeXExecuteLine"'|g' README.md
    fi

    git add .

    printf "\n"
    git status
    printf "\n"

    read -ep "$(echo -e ${CYAN}"Remove files? [N/(string)] "${NC})" choice
    while [[ ! -z $choice ]]; do
        git restore --staged "$choice"

        printf "\n"
        git status
        printf "\n"

        read -ep "$(echo -e ${CYAN}"Remove files? [N/(string)] "${NC})" choice
    done

    printf "\n"
    read -ep "$(echo -e ${CYAN}"Message: "${NC})" msg
    printf "\n"

    git commit -m "$msg"
    printf "\n"
    git push
else
    exit
fi

#!/bin/bash

YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

while [ ! -z "$1" ]; do
    prompt=$1
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
                    cd $HOME/Dropbox/MathWiki/
                ;;
                "2")
                    cd $HOME/.config/
                ;;
            esac
        ;;
        --MathWiki|-m)
            repo="1"
            cd "$HOME/Dropbox/MathWiki/"
    esac
shift
done

printf "\n"
status=$(git -c color.status=always status | tee /dev/tty)
if [[ $(echo -e "$status" | grep "no changes added to commit") ]] || [[ $(echo -e "$status" | grep "nothing to commit") ]]; then
    printf "\n"
fi

if [[ "$repo" == "1" ]]; then
    read -n 1 -ep "$(echo -e ${PURPLE}"Show diff? [Y/a/n]${NC} ")" choice
    if [ -z "$choice" ] || [ "$choice" == "Y" ]; then
        printf "\n"
        diff=$(git -c color.diff=always diff "Notes/*" | tee /dev/tty)
    elif [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
        printf "\n"
        diff=$(git -c color.diff=always diff | tee /dev/tty)
    elif [ "$choice" == "q" ]; then
        exit
    fi
else
    read -n 1 -ep "$(echo -e ${PURPLE}"Show diff? [Y/n]${NC} ")" choice
    if [ -z "$choice" ] || [ "$choice" == "Y" ]; then
        printf "\n"
        diff=$(git -c color.diff=always diff | tee /dev/tty)
    elif [ "$choice" == "q" ]; then
        exit
    fi
fi

if [[ $(echo "$diff" | tail -n1 | sed 's/\ .\ //g') ]]; then
    printf "\n"
fi

read -n 1 -ep "$(echo -e ${PURPLE}"Commit? [Y/n]${NC} ")" choice
if [ -z "$choice" ] || [ "$choice" == "Y" ]; then
    if [[ "$repo" == "1" ]]; then
        source ~/Dropbox/MathWiki/.scripts/stats.sh -u
        source ~/Dropbox/MathWiki/.scripts/stats.sh -r

        templatesInsertLine=$(grep -n "#### Templates" ~/.config/nvim/UltiSnips/markdown.snippets | sed 's/:.*$//g')
        sed -i 's|\[templatesInsert\]:.*$|\[templatesInsert\]: https://github.com/zhaoshenzhai/dotfiles/blob/master/nvim/UltiSnips/markdown.snippets#L'"$templatesInsertLine"'|g' README.md

        tikzInsertLine=$(grep -n "newTikZ.sh" ~/.config/nvim/config/MathWiki.vim | sed 's/:.*$//g')
        sed -i 's|\[tikzInsert\]:.*$|\[tikzInsert\]: https://github.com/zhaoshenzhai/dotfiles/blob/master/nvim/config/MathWiki.vim#L'"$tikzInsertLine"'|g' README.md

        pdfLaTeXExecuteLine=$(grep -n "pdflatex -shell-escape image.tex" ~/.config/nvim/config/MathWiki.vim | sed 's/:.*$//g')
        sed -i 's|\[pdfLaTeXExecute\]:.*$|\[pdfLaTeXExecute\]: https://github.com/zhaoshenzhai/dotfiles/blob/master/nvim/config/MathWiki.vim#L'"$pdfLaTeXExecuteLine"'|g' README.md

        autoAliasLine=$(grep -n "Math()" ~/Dropbox/MathWiki/.scripts/mathLinks.sh | sed 's/:.*$//g')
        sed -i 's|\[standardAlias\]:.*$|\[standardAlias\]: https://github.com/zhaoshenzhai/MathWiki/blob/master/.scripts/mathLinks.sh#L'"$autoAliasLine"'|g' README.md
    fi

    git add .

    printf "\n"
    status=$(git -c color.status=always status | tee /dev/tty)
    if [[ ! $(echo -e "$status" | grep "no changes added to commit") ]] && [[ ! $(echo -e "$status" | grep "nothing to commit") ]]; then
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

        res=$(git push 2>&1)
        fatal=$(echo $res | grep -o fatal)
        while [[ $fatal ]]; do
            echo -ne "${YELLOW}Connecting...${NC}\r"
            sleep 1
            res=$(git push 2>&1)
            fatal=$(echo $res | grep -o fatal)
        done
        echo "$res"
    fi

    if [[ "$prompt" == "-p" ]]; then
        printf "\n"
        read -n 1 -ep "$(echo -e ${CYAN}"Press [Y] to return, exiting otherwise...${NC} ")" repeat
        if [[ "$repeat" == "Y" ]] || [[ -z "$repeat" ]]; then
            clear
            ~/.config/scripts/gitCommit.sh -p
        else
            exit
        fi
    fi
else
    if [[ "$prompt" == "-p" ]]; then
        printf "\n"
        read -n 1 -ep "$(echo -e ${CYAN}"Press [Y] to return, exiting otherwise...${NC} ")" repeat
        if [[ "$repeat" == "Y" ]] || [[ -z "$repeat" ]]; then
            clear
            ~/.config/scripts/gitCommit.sh -p
        else
            exit
        fi
    fi
fi

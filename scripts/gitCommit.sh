#!/bin/bash

YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

if [[ -z $1 ]]; then
    echo -e "${CYAN}Repositories:${NC}"
    echo -e "${CYAN}    (1): MathWiki${NC}"
    echo -e "${CYAN}    (2): Dotfiles${NC}"
    echo -e "${CYAN}    (3): MathLinks${NC}"
    echo ""

    read -n 1 -ep "$(echo -e ${CYAN}"Select repository: [1-3]${NC} ")" repo
    if [ "$repo" == "q" ]; then
        exit
    fi

    re='^[0-9]+$'
    while ( ! [[ $repo =~ $re ]] ) || ( [ "$repo" -lt "1" ] || [ "$repo" -gt "3" ] ); do
        read -n 1 -ep "$(echo -e ${CYAN}"Select repository: [1-3]${NC} ")" repo
        if [[ "$repo" == "q" ]]; then
            exit
        fi
    done

    case $repo in
        "1")
            cd $HOME/Dropbox/MathWiki
        ;;
        "2")
            cd $HOME/Dropbox/Dotfiles
        ;;
        "3")
            cd $HOME/Dropbox/MathLinks
        ;;
    esac   
else
    prompt=$1
    case "$1" in
        --MathWiki|-m)
            repo="1"
            cd "$HOME/Dropbox/MathWiki/"
            source .scripts/stats.sh -u
            source .scripts/stats.sh -r
    esac
fi

echo ""
status=$(git -c color.status=always status | tee /dev/tty)
if [[ $(echo -e "$status" | grep "no changes added to commit") ]] || [[ $(echo -e "$status" | grep "nothing added to commit") ]]; then
    echo ""
fi

if [[ ! $(echo "$status" | grep "nothing to commit") ]]; then
    if [[ "$repo" == "1" ]]; then
        read -n 1 -ep "$(echo -e ${PURPLE}"Show diff? [Y/a/n]${NC} ")" choice
        if [ -z "$choice" ] || [ "$choice" == "Y" ]; then
            echo ""
            diff=$(git -c color.diff=always diff -- . ':(exclude).obsidian/*' | tee /dev/tty)
        elif [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
            echo ""
            diff=$(git -c color.diff=always diff | tee /dev/tty)
        elif [ "$choice" == "q" ]; then
            if [[ -z $prompt ]]; then
                echo ""
                read -n 1 -ep "$(echo -e ${CYAN}"Press [Y] to return, exiting otherwise...${NC} ")" repeat
                if [[ "$repeat" == "Y" ]] || [[ -z "$repeat" ]]; then
                    clear
                    ~/Dropbox/Dotfiles/scripts/gitCommit.sh
                fi
            fi
            exit
        fi
    else
        read -n 1 -ep "$(echo -e ${PURPLE}"Show diff? [Y/n]${NC} ")" choice
        if [ -z "$choice" ] || [ "$choice" == "Y" ]; then
            echo ""
            diff=$(git -c color.diff=always diff | tee /dev/tty)
        elif [ "$choice" == "q" ]; then
            if [[ -z $prompt ]]; then
                echo ""
                read -n 1 -ep "$(echo -e ${CYAN}"Press [Y] to return, exiting otherwise...${NC} ")" repeat
                if [[ "$repeat" == "Y" ]] || [[ -z "$repeat" ]]; then
                    clear
                    ~/Dropbox/Dotfiles/scripts/gitCommit.sh
                fi
            fi
            exit
        fi
    fi

    if [[ $(echo "$diff" | tail -n1 | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | grep -E '\S') ]]; then
        echo ""
    fi
    read -n 1 -ep "$(echo -e ${PURPLE}"Commit? [Y/n]${NC} ")" choice
    if [ -z "$choice" ] || [ "$choice" == "Y" ]; then
        git add .
        echo ""
        status=$(git -c color.status=always status | tee /dev/tty)
        if [[ $(echo -e "$status" | grep "no changes added to commit") ]] || [[ $(echo -e "$status" | grep "nothing added to commit") ]]; then
            echo ""
        fi
        read -ep "$(echo -e ${PURPLE}"Remove files? [N/(string)]${NC} ")" choice
        while [[ ! -z $choice ]]; do
            git restore --staged "$choice"

            echo ""
            status=$(git -c color.status=always status | tee /dev/tty)
            if [[ $(echo -e "$status" | grep "no changes added to commit") ]] || [[ $(echo -e "$status" | grep "nothing added to commit") ]]; then
                echo ""
            fi

            read -ep "$(echo -e ${PURPLE}"Remove files? [N/(string)]${NC} ")" choice
        done

        echo ""
        read -ep "$(echo -e ${PURPLE}"Message:${NC} ")" msg
        while [ -z "$msg" ]; do
            read -ep "$(echo -e ${PURPLE}"Message:${NC} ")" msg
        done
        echo ""

        git commit -m "$msg"
        echo ""

        res=$(git push 2>&1)
        fatal=$(echo $res | grep -o fatal)
        attempt=1
        while [[ $fatal ]]; do
            echo -ne "${YELLOW}Connecting... (x$attempt)${NC}\r"
            sleep 1
            res=$(git push 2>&1)
            fatal=$(echo $res | grep -o fatal)
            attempt=$(($attempt + 1))
        done
        echo "$res"
    fi

    if [[ -z $prompt ]]; then
        echo ""
        read -n 1 -ep "$(echo -e ${CYAN}"Press [Y] to return, exiting otherwise...${NC} ")" repeat
        if [[ "$repeat" == "Y" ]] || [[ -z "$repeat" ]]; then
            clear
            ~/Dropbox/Dotfiles/scripts/gitCommit.sh
        fi
        exit
    fi
else
    if [[ -z $prompt ]]; then
        echo ""
        read -n 1 -ep "$(echo -e ${CYAN}"Press [Y] to return, exiting otherwise...${NC} ")" repeat
        if [[ "$repeat" == "Y" ]] || [[ -z "$repeat" ]]; then
            clear
            ~/Dropbox/Dotfiles/scripts/gitCommit.sh
        fi
        exit
    fi
fi

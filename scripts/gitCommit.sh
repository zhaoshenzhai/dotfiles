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
if [[ $(echo -e "$status" | grep "no changes added to commit") ]] || [[ $(echo -e "$status" | grep "nothing added to commit") ]]; then
    printf "\n"
fi

if [[ ! $(echo "$status" | grep "nothing to commit") ]]; then
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

    if [[ $(echo "$diff" | tail -n1 | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | grep -E '\w') ]]; then
        printf "\n"
    fi
    read -n 1 -ep "$(echo -e ${PURPLE}"Commit? [Y/n]${NC} ")" choice
    if [ -z "$choice" ] || [ "$choice" == "Y" ]; then
        git add .
        printf "\n"
        status=$(git -c color.status=always status | tee /dev/tty)
        if [[ $(echo -e "$status" | grep "no changes added to commit") ]] || [[ $(echo -e "$status" | grep "nothing added to commit") ]]; then
            printf "\n"
        fi
        read -ep "$(echo -e ${PURPLE}"Remove files? [N/(string)]${NC} ")" choice
        while [[ ! -z $choice ]]; do
            git restore --staged "$choice"

            printf "\n"
            status=$(git -c color.status=always status | tee /dev/tty)
            if [[ $(echo -e "$status" | grep "no changes added to commit") ]] || [[ $(echo -e "$status" | grep "nothing added to commit") ]]; then
                printf "\n"
            fi

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

#!/bin/bash

if [[ -z $1 ]]; then
    echo -e "${CYAN}Repositories:${NC}"
    echo -e "${CYAN}    (1): MathWiki${NC}"
    echo -e "${CYAN}    (2): Dotfiles${NC}"
    echo -e "${CYAN}    (3): SURA2023${NC}"
    echo -e "${CYAN}    (4): DRP2023${NC}"
    echo -e "${CYAN}    (5): MathLinks${NC}"
    echo ""

    read -n 1 -ep "$(echo -e ${CYAN}"Select repository: [1|(1-5)]${NC} ")" repo
    re='^[0-9]+$'
    if ( [[ $repo =~ $re ]] ) && ( [ "$repo" -gt "0" ] && [ "$repo" -le "5" ] ) || [[ -z "$repo" ]]; then
        if [[ -z "$repo" ]]; then
            repo="1"
        fi
    elif [[ "$repo" == "q" ]]; then
        exit
    else
        clear
        $DOTFILES_DIR/scripts/gitCommit.sh
        exit
    fi

    case $repo in
        "1")
            cd $MATHWIKI_DIR
            source $MATHWIKI_DIR/.scripts/stats.sh -u
            source $MATHWIKI_DIR/.scripts/stats.sh -r
        ;;
        "2")
            cd $DOTFILES_DIR
        ;;
        "3")
            cd $HOME/Dropbox/University/Courses/2023_05_Y1_Summer/SURA23S/Paper
        ;;
        "4")
            cd $HOME/Dropbox/University/Courses/2023_01_Y1_Winter/DRP2023_Moduli_Spaces_of_Riemann_Surfaces
        ;;
        "5")
            cd $HOME/Dropbox/MathLinks
        ;;
    esac   
else
    prompt=$1
    case "$1" in
        --MathWiki|-m)
            repo="1"
            source $MATHWIKI_DIR/.scripts/stats.sh -u
            source $MATHWIKI_DIR/.scripts/stats.sh -r
            cd $MATHWIKI_DIR
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
            diff=$(git -c color.diff=always diff --color-words -- . ':(exclude).obsidian/*' | tee /dev/tty)
        elif [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
            echo ""
            diff=$(git -c color.diff=always diff --color-words | tee /dev/tty)
        elif [ "$choice" == "q" ]; then
            if [[ -z $prompt ]]; then
                echo ""
                read -n 1 -ep "$(echo -e ${CYAN}"Press [Y] to return, exiting otherwise...${NC} ")" repeat
                if [[ "$repeat" == "Y" ]] || [[ -z "$repeat" ]]; then
                    clear
                    $DOTFILES_DIR/scripts/gitCommit.sh
                fi
            fi
            exit
        fi
    else
        read -n 1 -ep "$(echo -e ${PURPLE}"Show diff? [Y/n]${NC} ")" choice
        if [ -z "$choice" ] || [ "$choice" == "Y" ]; then
            echo ""
            diff=$(git -c color.diff=always diff --color-words | tee /dev/tty)
        elif [ "$choice" == "q" ]; then
            if [[ -z $prompt ]]; then
                echo ""
                read -n 1 -ep "$(echo -e ${CYAN}"Press [Y] to return, exiting otherwise...${NC} ")" repeat
                if [[ "$repeat" == "Y" ]] || [[ -z "$repeat" ]]; then
                    clear
                    $DOTFILES_DIR/scripts/gitCommit.sh
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
            $DOTFILES_DIR/scripts/gitCommit.sh
        fi
        exit
    fi
else
    if [[ -z $prompt ]]; then
        echo ""
        read -n 1 -ep "$(echo -e ${CYAN}"Press [Y] to return, exiting otherwise...${NC} ")" repeat
        if [[ "$repeat" == "Y" ]] || [[ -z "$repeat" ]]; then
            clear
            $DOTFILES_DIR/scripts/gitCommit.sh
        fi
        exit
    fi
fi

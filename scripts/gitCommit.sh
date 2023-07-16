#!/bin/bash

REPOS="
MathWiki     $MATHWIKI_DIR
Dotfiles     $DOTFILES_DIR
Courses      $UNIVERSITY_DIR/Courses
SURA2023     $UNIVERSITY_DIR/Courses/SURA23S_Curve_Systems_on_Surfaces
MathLinks    $MATHLINKS_DIR"

REPOS=$(echo "$REPOS" | sed 1d)
REPOSNUM=$(echo "$REPOS" | wc -l)
REPONAMES=$(echo "$REPOS" | cut -f 1 -d ' ')
REPOPATHS=$(echo "$REPOS" | cut -f 1 -d ' ' --complement | sed 's/\ *//g')

if [[ -z $1 ]]; then
    while [[ -z $valid ]]; do
        echo -e "${CYAN}Repositories:${NC}"
        repoIndex=1
        while IFS= read -r repoName; do
            echo -e "    ${CYAN}($repoIndex): $repoName${NC}"
            repoIndex=$((repoIndex + 1))
        done <<< "$REPONAMES"
        echo ""

        read -n 1 -ep "$(echo -e ${CYAN}"Select repository: [1-$REPOSNUM]${NC} ")" repo
        re='^[0-9]+$'
        if [[ "$repo" == "q" ]]; then
            exit
        elif [[ -z $repo ]] || ([[ $repo =~ $re ]] && [[ $repo -gt 0 ]] && [[ $repo -le $REPOSNUM ]]); then
            valid=1
        else
            clear
        fi
    done

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
            cd $UNIVERSITY_DIR/Courses
        ;;
        "4")
            cd $UNIVERSITY_DIR/Courses/SURA23S_Curve_Systems_on_Surfaces
        ;;
        "5")
            cd $MATHLINKS_DIR
        ;;
        *)
            changedRepos=""
            changedReposNum=0
            repoIndex=1
            repoIndices=""
            while IFS= read -r repo; do
                cd $(echo $repo | cut -f 1 -d ' ' --complement | sed 's/\ *//g')
                status=$(git -c color.status=always status 2>&1)
                if [[ ! $(echo -e "$status" | grep "nothing to commit, working tree clean") ]]; then
                    changedRepos="$changedRepos\n$repo"
                    changedReposNum=$((changedReposNum + 1))
                    repoIndices="$repoIndices$repoIndex"
                fi
                repoIndex=$((repoIndex + 1))
            done <<< "$REPOS"

            changedRepos=$(echo "$changedRepos" | sed -e 's/^\\n//g')

            if [[ $changedReposNum = 0 ]]; then
                repo=1
            elif [[ $changedReposNum = 1 ]]; then
                repo=$(echo "$repoIndices" | head -c 1 | tail -c 1)
                cd $(echo "$REPOPATHS" | sed "${repo}q;d")
            else
                clear
                while [[ -z $changedValid ]]; do
                    changedRepoNames=$(echo -e "$changedRepos" | cut -f 1 -d ' ')
                    echo -e "${CYAN}Changed Repositories:${NC}"
                    repoIndex=1
                    while IFS= read -r repo; do
                        echo -e "    ${CYAN}($repoIndex): $repo${NC}"
                        repoIndex=$((repoIndex + 1))
                    done <<< "$changedRepoNames"
                    echo ""

                    read -n 1 -ep "$(echo -e ${CYAN}"Select repository: [1-$changedReposNum]${NC} ")" changedRepo
                    re='^[0-9]+$'
                    if [[ "$changedRepo" == "q" ]]; then
                        exit
                    elif [[ $changedRepo =~ $re ]] && [[ "$changedRepo" -gt "0" ]] && [[ "$changedRepo" -le "$changedReposNum" ]]; then
                        changedValid=1
                    else
                        clear
                    fi
                done

                repo=$(echo "$repoIndices" | head -c $changedRepo | tail -c 1)
                cd $(echo "$REPOPATHS" | sed "${repo}q;d")
                echo -e "${YELLOW}$repo${NC}"
                if [[ $repo == 1 ]]; then
                    echo -e "${YELLOW}hi${NC}"
                    source $MATHWIKI_DIR/.scripts/stats.sh -u
                    source $MATHWIKI_DIR/.scripts/stats.sh -r
                fi
            fi
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
ignoredFiles=$(git ls-files -i -c --exclude-from=.gitignore)
if [[ ! -z $ignoredFiles ]]; then
    git rm --cached $ignoredFiles
fi
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
                    $DOTFILES_DIR/scripts/gitCommit.sh
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

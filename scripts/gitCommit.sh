#!/bin/bash

REPOS="
Courses         $UNIVERSITY_DIR/Courses
Dotfiles        $DOTFILES_DIR
MathWiki        $MATHWIKI_DIR
SURA-2023       $UNIVERSITY_DIR/Courses/.old/SURA23S_Curve_Systems_on_Surfaces
SURA-2024       $UNIVERSITY_DIR/Courses/.old/SURA24S_Quasi-treeings_are_treeable
COMP527-Project $UNIVERSITY_DIR/Courses/COMP527_Logic_and_Computation/Project"

REPOS=$(echo "$REPOS" | sed 1d)
REPOSNUM=$(echo "$REPOS" | wc -l)
REPONAMES=$(echo "$REPOS" | cut -f 1 -d ' ')
REPOPATHS=$(echo "$REPOS" | cut -f 1 -d ' ' --complement | sed 's/\ *//g')

specifiedRepo=
repoNum=

HELP() {
    echo -e "Usage: ./gitCommit.sh"
    echo -e "    Optional: [-r specifiedRepo]"
}
GETSTATUS() {
    if [[ -z $1 ]]; then
        if [[ $repoName == "MathWiki" ]] || [[ $repoNum == 1 ]]; then
            echo $(git -c color.status=always status ':(exclude)docs/*' ':(exclude)Site/static/allFiles.json' 2>&1)
        else
            echo $(git -c color.status=always status 2>&1)
        fi
    else
        if [[ $repoName == "MathWiki" ]] || [[ $repoNum == 1 ]]; then
            echo $(git -c color.status=always status ':(exclude)docs/*' ':(exclude)Site/static/allFiles.json' | tee /dev/tty)
        else
            echo $(git -c color.status=always status | tee /dev/tty)
        fi
    fi
}
UPDATE() {
    repoName=$1
    if [[ $1 == "MathWiki" ]]; then
        cd $MATHWIKI_DIR
        source $MATHWIKI_DIR/.scripts/publish.sh
        source $MATHWIKI_DIR/.scripts/stats.sh -u
        source $MATHWIKI_DIR/.scripts/stats.sh -r
        repoNum="1"
    fi
}
SHOWDIFF() {
    if [[ $repoName == "MathWiki" ]] || [[ $repoNum == 1 ]]; then
        SHOWDIFFHELPER "docs/*" "Site/static/allFiles.json"
    else
        SHOWDIFFHELPER
    fi

    if [[ $(echo "$diff" | tail -n1 | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | grep -E '\S') ]]; then
        echo ""
    fi
}
SHOWDIFFHELPER() {
    read -n 1 -ep "$(echo -e ${PURPLE}"Show diff? [Y/n]${NC} ")" choice
    if [ -z "$choice" ] || [ "$choice" == "Y" ]; then
        echo ""
        if [[ ! -z $2 ]]; then
            diff=$(git -c color.diff=always diff -- . ":(exclude)$1" ":(exclude)$2" | tee /dev/tty)
        elif [[ ! -z $1 ]]; then
            diff=$(git -c color.diff=always diff -- . ":(exclude)$1" | tee /dev/tty)
        else
            diff=$(git -c color.diff=always diff | tee /dev/tty)
        fi
    elif [ "$choice" == "q" ]; then
        EXIT
    fi
}
SHOWSTATUS() {
    status=$(GETSTATUS -s)
    if [[ $(echo -e "$status" | grep "no changes added to commit") ]] || [[ $(echo -e "$status" | grep "nothing added to commit") ]]; then
        echo ""
    fi
}
EXIT() {
    if [[ -z $specifiedRepo ]]; then
        echo ""
        read -n 1 -ep "$(echo -e ${CYAN}"Press [Y] to return, exiting otherwise...${NC} ")" repeat
        if [[ "$repeat" == "Y" ]] || [[ -z "$repeat" ]]; then
            clear
            $DOTFILES_DIR/scripts/gitCommit.sh
        fi
    fi
    exit
}

# Input
while [[ ! -z $1 ]]; do
    case $1 in
        -h|--help)
            HELP
            exit 0
            ;;
        -r)
            specifiedRepo=$2
            ;;
    esac
    shift
    shift
done

# Update repos to prepare for git commands
if [[ ! -z $specifiedRepo ]]; then
    UPDATE =$specifiedRepo
else
    # Print all repos
    while [[ -z $valid ]]; do
        echo -e "${CYAN}Repositories:${NC}"
        repoIndex=1
        while IFS= read -r repoName; do
            echo -e "    ${CYAN}($repoIndex): $repoName${NC}"
            repoIndex=$((repoIndex + 1))
        done <<< "$REPONAMES"
        echo ""

        read -n 1 -ep "$(echo -e ${CYAN}"Select repository: [1-$REPOSNUM]${NC} ")" repoNum
        re='^[0-9]+$'
        if [[ "$repoNum" == "q" ]]; then
            exit
        elif [[ -z $repoNum ]] || ([[ $repoNum =~ $re ]] && [[ $repoNum -gt 0 ]] && [[ $repoNum -le $REPOSNUM ]]); then
            valid=1
        else
            clear
        fi
    done

    # Process and move to selected repo
    case $repoNum in
        "1")
            cd $UNIVERSITY_DIR/Courses
        ;;
        "2")
            cd $DOTFILES_DIR
        ;;
        "3")
            cd $MATHWIKI_DIR
            UPDATE "MathWiki"
        ;;
        "4")
            cd $UNIVERSITY_DIR/Courses/.old/SURA24S_Quasi-treeings_are_treeable
        ;;
        "5")
            cd $UNIVERSITY_DIR/Courses/.old/SURA23S_Curve_Systems_on_Surfaces
        ;;
        "6")
            cd $UNIVERSITY_DIR/Courses/COMP527_Logic_and_Computation/Project
        ;;
        *)
            changedRepos=""
            changedReposNum=0
            repoIndex=1
            repoIndices=""
            while IFS= read -r repoInfo; do
                repoPath=$(echo $repoInfo | cut -f 1 -d ' ' --complement | sed 's/\ *//g')
                repoName=$(echo $repoInfo | cut -f 1 -d ' ')
                cd $repoPath
                status=$(GETSTATUS)
                if [[ ! $(echo -e "$status" | grep "nothing to commit, working tree clean") ]]; then
                    changedRepos="$changedRepos\n$repoInfo"
                    changedReposNum=$((changedReposNum + 1))
                    repoIndices="$repoIndices$repoIndex"
                fi
                repoIndex=$((repoIndex + 1))
            done <<< "$REPOS"

            changedRepos=$(echo "$changedRepos" | sed -e 's/^\\n//g')

            if [[ $changedReposNum = 0 ]]; then
                repoNum=1
            elif [[ $changedReposNum = 1 ]]; then
                repoNum=$(echo "$repoIndices" | head -c 1 | tail -c 1)
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
                repoNum=$(echo "$repoIndices" | head -c $changedRepo | tail -c 1)
                repoName=$(echo "$changedRepoNames" | head -$changedRepo | tail -1)
            fi

            cd $(echo "$REPOPATHS" | sed "${repoNum}q;d")
            UPDATE $repoName
        ;;
    esac
fi

# Ignore files
echo ""
ignoredFiles=$(git ls-files -i -c --exclude-from=.gitignore)
if [[ ! -z $ignoredFiles ]]; then
    git rm --cached $ignoredFiles
fi

# Show diff and commit
SHOWSTATUS
if [[ $(echo "$status" | grep "nothing to commit") ]]; then
    EXIT
else
    SHOWDIFF

    read -n 1 -ep "$(echo -e ${PURPLE}"Commit? [Y/n]${NC} ")" choice
    if [ -z "$choice" ] || [ "$choice" == "Y" ]; then
        git add .
        echo ""
        SHOWSTATUS

        # Remove Files
        read -ep "$(echo -e ${PURPLE}"Remove files? [N/(string)]${NC} ")" choice
        while [[ ! -z $choice ]]; do
            git restore --staged "$choice"
            echo ""
            SHOWSTATUS

            read -ep "$(echo -e ${PURPLE}"Remove files? [N/(string)]${NC} ")" choice
        done

        # Commit
        echo ""
        read -ep "$(echo -e ${PURPLE}"Message:${NC} ")" msg
        while [ -z "$msg" ]; do
            read -ep "$(echo -e ${PURPLE}"Message:${NC} ")" msg
        done
        echo ""

        git commit -m "$msg"
        echo ""

        # Push
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

    EXIT
fi

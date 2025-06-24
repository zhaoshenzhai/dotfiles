#!/bin/bash

courseFolder=$PWD
filesPath=$DOTFILES_DIR/files/LaTeXAssignmentsTemplate/
template="template.tex"

assignmentNumber=
dueMonth=
dueDate=
dueDateMod=
questionStart=
questionEnd=
section=
subsection=
collabInfo=

# Fix dates
FIX_DATE() {
    case $dueMonth in
        Jan|1|01)
            dueMonth=January
            ;;
        Feb|2|02)
            dueMonth=February
            ;;
        Mar|3|03)
            dueMonth=March
            ;;
        Apr|4|04)
            dueMonth=April
            ;;
        May|5|05)
            dueMonth=May
            ;;
        Jun|6|06)
            dueMonth=June
            ;;
        Jul|7|07)
            dueMonth=July
            ;;
        Aug|8|08)
            dueMonth=August
            ;;
        Sep|9|09)
            dueMonth=September
            ;;
        Oct|10)
            dueMonth=October
            ;;
        Nov|11)
            dueMonth=November
            ;;
        Dec|12)
            dueMonth=December
            ;;
    esac

    case $dueDate in
        1|21|31)
            dueDateMod=st
            ;;
        2|22)
            dueDateMod=nd
            ;;
        3|23)
            dueDateMod=rd
            ;;
        *)
            dueDateMod=th
            ;;
    esac
}

# Help
HELP() {
    echo -e "Usage: ./newAssignment.sh [-a assignmentNumber] [-d dueMonth dueDate]"
    echo -e "    Optional: [-qs questionStart] [-qe questionEnd] [-s section] [-S subsection] [-c collabInfo]"
}

# Create files
CREATE() {
    file=$1

    cp -r $filesPath*.sty $PWD
    cp -r $filesPath/$template $PWD
    mv $template $file.tex

    courseName=$(echo $courseFolder | sed -E 's/^.*([A-Z]{4}[0-9]{3})/\1/g' | sed 's/_/\ /g' | sed '0,/\ /{s/\ /\ -\ /}')
    termYear=$(cat "$courseFolder/.info")
    displayedTitle=$(echo $file | sed 's/_/\ /g')
    exerciseNumber=0

    if [[ ! -z $2 ]]; then
        displayedTitle=$(echo $displayedTitle | sed 's/^/Assignment\ '$assignmentNumber'\ |\ /g')
        exerciseNumber=$(($(echo $file | sed 's/Question_//g') - 1))
    fi

    sed -i 's/COURSE_NAME/'"$courseName"'/g' preamble.sty
    sed -i 's/TERM_YEAR/'"$termYear"'/g' preamble.sty
    sed -i 's/EXERCISE_NUMBER/'"$exerciseNumber"'/g' preamble.sty
    sed -i 's/TITLE/'"$displayedTitle"'/g' $file.tex
    sed -i 's/COLLAB_INFO/'"$collabInfo"'/g' $file.tex
    sed -i 's/DUE_MONTH/'"$dueMonth"'/g' $file.tex
    sed -i 's/DUE_DATE_MOD/'"$dueDateMod"'/g' $file.tex
    sed -i 's/DUE_DATE/'"$dueDate"'/g' $file.tex

    setCounterLine=$(grep -n "setcounter" "$filesPath/preamble.sty" | sed 's/:.*//')
    if [[ ! -z $section ]]; then
        sed -i ''"$setCounterLine"'s/$/\n\\setcounter{section}{'"$section"'}/g' preamble.sty
        sed -i 's/{exercise}{Exercise}.*/{exercise}{Exercise}[section]/g' preamble.sty
    fi
    if [[ ! -z $subsection ]]; then
        sed -i ''"$((setCounterLine + 1))"'s/$/\n\\setcounter{subsection}{'"$subsection"'}/g' preamble.sty
        sed -i 's/{exercise}{Exercise}.*/{exercise}{Exercise}[subsection]/g' preamble.sty
    fi
}

# Input
while [[ ! -z $1 ]]; do
    case $1 in
        -h|--help)
            HELP
            exit 0
            ;;
        -a)
            assignmentNumber=$2
            ;;
        -d)
            dueMonth=$2
            dueDate=$3
            FIX_DATE
            shift
            ;;
        -qs)
            questionStart=$2
            ;;
        -qe)
            questionEnd=$2
            ;;
        -s)
            section=$2
            ;;
        -S)
            subsection=$2
            ;;
        -c)
            template="template_c.tex"
            collabInfo=$2
    esac
    shift
    shift
done

# Validate
if [[ -z $assignmentNumber ]] || [[ -z $dueMonth ]] || [[ -z $dueDate ]]; then
    echo -e "${RED}Error: Expected at least [-a] [-d] flags.${NC}"
    HELP
    exit 1
fi

re='^[0-9]+$'
if [[ ! $assignmentNumber =~ $re ]] || [[ $assignmentNumber -lt 1 ]] || [[ ! $dueDate =~ $re ]] || [[ $dueDate -lt 1 ]] || [[ $dueDate -gt 31 ]]; then
    echo "Error: Invalid inputs."
    exit 2
fi

if [[ ! -z $questionStart ]] && ([[ $questionStart -lt 1 ]] || ([[ ! -z $questionEnd ]] && [[ $questionStart -gt $questionEnd ]])); then
    echo "Error: Invalid inputs."
    exit 2
fi

mkdir -p Assignments/Assignment_$assignmentNumber
cd Assignments/Assignment_$assignmentNumber

if [[ ! -z $questionEnd ]]; then
    if [[ -z $questionStart ]]; then questionStart=1; fi
    for i in $(eval echo {$questionStart..$questionEnd}); do
        file=Question_$i
        mkdir $file
        cd $file
        CREATE $file MODIFY_TITLE
        cd ..
    done
else
    CREATE Assignment_$assignmentNumber
fi

#!/bin/bash

YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

filesPath=$DOTFILES_DIR/files/assignmentsTemplate/
template="template.tex"

assignmentNumber=
numberOfQuestions=
dueMonth=
dueDate=
dueDateMod=
section=
subsection=
collabInfo=

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

HELP() {
    echo -e "Usage: ./newAssignment.sh [-a assignmentNumber] [-q numberOfQuestions] [-d dueMonth dueDate]"
    echo -e "    Optional: [-s section] [-S subsection] [-c collabInfo]"
}

while [[ ! -z $1 ]]; do
    case $1 in
        -h|--help)
            HELP
            exit 0
            ;;
        -a)
            assignmentNumber=$2
            ;;
        -q)
            numberOfQuestions=$2
            ;;
        -d)
            dueMonth=$2
            dueDate=$3
            FIX_DATE
            shift
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

if [[ -z $assignmentNumber ]] || [[ -z $numberOfQuestions ]] || [[ -z $dueMonth ]] || [[ -z $dueDate ]]; then
    echo -e "${RED}Error: Expected at least [-a] [-q] [-d] flags.${NC}"
    HELP
    exit 1
fi

re='^[0-9]+$'
if [[ ! $assignmentNumber =~ $re ]] || [[ $assignmentNumber -lt 1 ]] || [[ ! $numberOfQuestions =~ $re ]] || [[ $numberOfQuestions -lt 1 ]] || [[ ! $dueDate =~ $re ]] || [[ $dueDate -lt 1 ]] || [[ $dueDate -gt 31 ]]; then
    echo "Error: Invalid inputs."
    exit 2
fi

mkdir Assignment_$assignmentNumber
cd Assignment_$assignmentNumber
for i in $(eval echo {1..$numberOfQuestions}); do
    file=Question_$i
    mkdir $file
    cd $file

    cp -r $filesPath*.sty $PWD
    cp -r $filesPath/$template $PWD
    mv $template $file.tex

    courseName=$(echo $PWD | grep -Po "[A-Z]{4}[1-9]{3}.*/" | sed 's/\/.*//g' | sed 's/_/\ /g' | sed '0,/\ /{s/\ /\ -\ /}')
    termYear=$(echo $PWD | grep -Po "Y\d_.*/" | sed 's/\/.*//g' | sed 's/^.*_//g')\ $(echo $PWD | grep -Po "20\d\d")
    displayedTitle=$(echo $file | sed 's/_/\ /g' | sed 's/^/Assignment\ '$assignmentNumber'\ |\ /g')
    exerciseNumber=$(($(echo $file | sed 's/Question_//g') - 1))

    sed -i 's/COURSE_NAME/'"$courseName"'/g' $file.tex
    sed -i 's/TERM_YEAR/'"$termYear"'/g' $file.tex
    sed -i 's/TITLE/'"$displayedTitle"'/g' $file.tex
    sed -i 's/EXERCISE_NUMBER/'"$exerciseNumber"'/g' $file.tex
    sed -i 's/COLLAB_INFO/'"$collabInfo"'/g' $file.tex
    sed -i 's/DUE_MONTH/'"$dueMonth"'/g' $file.tex
    sed -i 's/DUE_DATE_MOD/'"$dueDateMod"'/g' $file.tex
    sed -i 's/DUE_DATE/'"$dueDate"'/g' $file.tex

    setCounterLine=$(grep -n "setcounter" $filesPath/$template | sed 's/:.*//')
    if [[ ! -z $section ]]; then
        sed -i ''"$setCounterLine"'s/$/\n    \\setcounter{section}{'"$section"'}/g' $file.tex
        sed -i 's/{exercise}{Exercise}.*/{exercise}{Exercise}[section]/g' $file.tex
    fi
    if [[ ! -z $subsection ]]; then
        sed -i ''"$((setCounterLine + 1))"'s/$/\n    \\setcounter{subsection}{'"$subsection"'}/g' $file.tex
        sed -i 's/{exercise}{Exercise}.*/{exercise}{Exercise}[subsection]/g' $file.tex
    fi

    cd ..
done

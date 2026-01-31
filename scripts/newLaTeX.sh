#!/bin/bash

templatePath=~/iCloud/Dotfiles/files/LaTeXTemplate
fileName=
fileType=
title=
solutions=

assignmentCourse=
assignmentNumber=
assignmentDueMonth=
assignmentDueDate=
assignmentDueDateMod=

FIX_DATE() {
    case $assignmentDueMonth in
        Jan|1|01)
            assignmentDueMonth=January
            ;;
        Feb|2|02)
            assignmentDueMonth=February
            ;;
        Mar|3|03)
            assignmentDueMonth=March
            ;;
        Apr|4|04)
            assignmentDueMonth=April
            ;;
        May|5|05)
            assignmentDueMonth=May
            ;;
        Jun|6|06)
            assignmentDueMonth=June
            ;;
        Jul|7|07)
            assignmentDueMonth=July
            ;;
        Aug|8|08)
            assignmentDueMonth=August
            ;;
        Sep|9|09)
            assignmentDueMonth=September
            ;;
        Oct|10)
            assignmentDueMonth=October
            ;;
        Nov|11)
            assignmentDueMonth=November
            ;;
        Dec|12)
            assignmentDueMonth=December
            ;;
    esac

    case $assignmentDueDate in
        1|21|31)
            assignmentDueDateMod=st
            ;;
        2|22)
            assignmentDueDateMod=nd
            ;;
        3|23)
            assignmentDueDateMod=rd
            ;;
        *)
            assignmentDueDateMod=th
            ;;
    esac
}

COPY_FILES() {
    cp "$templatePath/macros.sty" .
    cp "$templatePath/refs.bib" .
    cp "$templatePath/preamble.sty" .
    cp "$templatePath/preambles/$fileType.sty" .
    cp "$templatePath/files/$fileType.tex" "$fileName.tex"

    sed -i 's/TITLE/'"$title"'/g' "$fileName.tex"
}

# Input
while [[ -n "$\{1-}" ]]; do
    case "$\{1-}" in
        -n)
            fileName=$2
            title=$(echo $fileName | sed 's/_/ /g')
            shift 2
            ;;
        -t)
            fileType=$2
            shift 2
            ;;
        -a)
            assignmentNumber=$2
            assignmentCourse=$PWD
            fileType=assignment
            fileName=Assignment_$2
            title=$(echo $fileName | sed 's/_/ /g')
            shift 2
            ;;
        -s)
            solutions=1
            shift 1
            ;;
        -d)
            assignmentDueMonth=$2
            assignmentDueDate=$3
            FIX_DATE
            shift 3
            ;;
        *)
            shift
            ;;
    esac
    shift
    shift
done

# Validate
if [[ -z $fileName ]]; then
    echo -e "${RED}Error: Expected one of: [-n] and [-a].${NC}"
    exit 1
fi

if [[ -z "$fileType" ]]; then
    if [[ -z "$assignmentNumber" ]]; then
        fileType=paper
    else
        fileType=assignment
    fi
fi

if [[ "$fileType" = "assignment" ]]; then
    if [ ! -f "$PWD/.info" ]; then
        echo -e "${RED}Error: Expected .info file.${NC}"
        exit 1
    fi

    if [[ -z $assignmentNumber ]] || [[ -z $assignmentDueMonth ]] || [[ -z $assignmentDueDate ]]; then
        echo -e "${RED}Error: Expected [-a] [-d] for assignmentNumber and (dueMonth dueDate).${NC}"
        exit 1
    fi

    re='^[0-9]+$'
    if [[ ! $assignmentNumber =~ $re ]] || [[ $assignmentNumber -lt 1 ]] || [[ ! $assignmentDueDate =~ $re ]] || [[ $assignmentDueDate -lt 1 ]] || [[ $assignmentDueDate -gt 31 ]]; then
        echo "Error: Invalid inputs."
        exit 2
    fi
fi

if [[ "$fileType" != "assignment" ]]; then
    mkdir "$fileName"
    cd "$fileName"
    COPY_FILES
fi

if [[ "$fileType" = "beamer" ]]; then
    ln -s "$templatePath/mcgill.png" .
elif [[ "$fileType" = "assignment" ]]; then
    mkdir -p "Assignments/$fileName"
    cd "Assignments/$fileName"
    COPY_FILES

    courseName=$(echo "$assignmentCourse" | sed -E 's/^.*([A-Z]{4}[0-9]{3})/\1/g' | sed 's/_/\ /g' | sed '0,/\ /{s/\ /\ $-$\ /}')
    termYear=$(cat "$assignmentCourse/.info")

    sed -i 's/COURSE_NAME/'"$courseName"'/g' "$fileName.tex"
    sed -i 's/TERM_YEAR/'"$termYear"'/g' "$fileName.tex"
    sed -i 's/DUE_MONTH/'"$assignmentDueMonth"'/g' "$fileName.tex"
    sed -i 's/DUE_DATE_MOD/'"$assignmentDueDateMod"'/g' "$fileName.tex"
    sed -i 's/DUE_DATE/'"$assignmentDueDate"'/g' "$fileName.tex"
fi

if [[ "$solutions" ]]; then
    ln -s "$templatePath/preambles/solutions.sty" .
    cp "$templatePath/.latexmkrc" .
    sed -i 's/\\input{macros.sty}/\\input{macros.sty}\n\\input{solutions.sty}/g' "$fileName.tex"
fi

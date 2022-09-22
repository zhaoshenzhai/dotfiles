#!/bin/bash

file=""
courseName=""
termYear=""
displayedTitle=""
dueDate="DUE_DATE"

while getopts 'f:t:d:' OPTION; do
    case "$OPTION" in
        f)
            file=$OPTARG
            mkdir $file
            cd $file

            cp -r $DOTFILES_DIR/files/assignmentsTemplate/* $PWD
            mv template.tex $file.tex

            courseName=$(echo $PWD | grep -Po "[A-Z]{4}[1-9]{3}.*/" | sed 's/\/.*//g' | sed 's/_/\ /g' | sed '0,/\ /{s/\ /\ -\ /}')
            termYear=$(echo $PWD | grep -Po "Y\d_.*/" | sed 's/\/.*//g' | sed 's/^.*_//g')\ $(echo $PWD | grep -Po "20\d\d")
            displayedTitle=$(echo $file | sed 's/_/\ /g')

            sed -i 's/COURSE_NAME/'"$courseName"'/g' $file.tex
            sed -i 's/TERM_YEAR/'"$termYear"'/g' $file.tex
        ;;
        t)
            displayedTitle=$OPTARG
            sed -i 's/TITLE/'"$displayedTitle"'/g' $file.tex
        ;;
        d)
            dueDate=$(echo $OPTARG | sed 's/\\/\\\\/g' | sed 's/\$/\\\$/g' | sed 's/\\t/\\\\\\t/g')
            sed -i 's/DUE_DATE/'"$dueDate"'/g' $file.tex
        ;;
  esac
done
shift "$(($OPTIND -1))"

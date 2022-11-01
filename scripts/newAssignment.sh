#!/bin/bash

file=""
template="template.tex"
courseName=""
termYear=""
displayedTitle=""
dueDate="DUE_DATE"

section="0"
subsection="0"

while getopts 'f:t:d:s:S:' OPTION; do
    case "$OPTION" in
        s)
            template="template_s.tex"
            subsection=$OPTARG
        ;;
        S)
            template="template_s.tex"
            section=$OPTARG
        ;;
        f)
            file=$OPTARG
            mkdir $file
            cd $file

            cp -r $DOTFILES_DIR/files/assignmentsTemplate/*.sty $PWD
            cp -r $DOTFILES_DIR/files/assignmentsTemplate/$template $PWD
            mv $template $file.tex

            courseName=$(echo $PWD | grep -Po "[A-Z]{4}[1-9]{3}.*/" | sed 's/\/.*//g' | sed 's/_/\ /g' | sed '0,/\ /{s/\ /\ -\ /}')
            termYear=$(echo $PWD | grep -Po "Y\d_.*/" | sed 's/\/.*//g' | sed 's/^.*_//g')\ $(echo $PWD | grep -Po "20\d\d")
            displayedTitle=$(echo $file | sed 's/_/\ /g')
            number=$(($(echo $file | sed 's/Question_//g') - 1))

            sed -i 's/COURSE_NAME/'"$courseName"'/g' $file.tex
            sed -i 's/TERM_YEAR/'"$termYear"'/g' $file.tex
            sed -i 's/TITLE/'"$displayedTitle"'/g' $file.tex

            sed -i 's/{section}{0}/{section}{'"$section"'}/g' $file.tex
            sed -i 's/{subsection}{0}/{subsection}{'"$subsection"'}/g' $file.tex
            sed -i 's/{exercise}{0}/{exercise}{'"$number"'}/g' $file.tex
        ;;
        t)
            displayedTitleNew=$OPTARG
            sed -i 's/'"$displayedTitle"'/'"$displayedTitleNew"'/g' $file.tex
        ;;
        d)
            dueDate=$(echo $OPTARG | sed 's/\\/\\\\/g' | sed 's/\$/\\\$/g' | sed 's/\\t/\\t/g')
            sed -i 's/DUE_DATE/'"$dueDate"'/g' $file.tex
        ;;
    esac
done
shift "$(($OPTIND -1))"

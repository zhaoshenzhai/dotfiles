#!/bin/bash

filesPath=$DOTFILES_DIR/files/assignmentsTemplate/
template="template.tex"

file=""
courseName=""
termYear=""
displayedTitle=""
dueDate="DUE_DATE"
setCounterLine=0
collabInfo=""

while getopts 'c:f:t:d:s:S:' OPTION; do
    case "$OPTION" in
        c)
            template="template_c.tex"
            collabInfo=$OPTARG
        ;;
        s)
            setCounterLine=$(grep -n "setcounter" $filesPath/$template | sed 's/:.*//')
            subsection=$OPTARG
        ;;
        S)
            setCounterLine=$(grep -n "setcounter" $filesPath/$template | sed 's/:.*//')
            section=$OPTARG
        ;;
        f)
            file=$OPTARG
            mkdir $file
            cd $file

            cp -r $filesPath*.sty $PWD
            cp -r $filesPath/$template $PWD
            mv $template $file.tex

            courseName=$(echo $PWD | grep -Po "[A-Z]{4}[1-9]{3}.*/" | sed 's/\/.*//g' | sed 's/_/\ /g' | sed '0,/\ /{s/\ /\ -\ /}')
            termYear=$(echo $PWD | grep -Po "Y\d_.*/" | sed 's/\/.*//g' | sed 's/^.*_//g')\ $(echo $PWD | grep -Po "20\d\d")
            displayedTitle=$(echo $file | sed 's/_/\ /g')
            number=$(($(echo $file | sed 's/Question_//g') - 1))

            sed -i 's/COURSE_NAME/'"$courseName"'/g' $file.tex
            sed -i 's/TERM_YEAR/'"$termYear"'/g' $file.tex
            sed -i 's/TITLE/'"$displayedTitle"'/g' $file.tex

            sed -i 's/{exercise}{0}/{exercise}{'"$number"'}/g' $file.tex

            if [[ ! -z $section ]]; then
                sed -i ''"$setCounterLine"'s/$/\n    \\setcounter{section}{'"$section"'}/g' $file.tex
            fi

            if [[ ! -z $subsection ]]; then
                sed -i ''"$((setCounterLine + 1))"'s/$/\n    \\setcounter{subsection}{'"$subsection"'}/g' $file.tex
            fi

            sed -i 's/COLLAB_INFO/'"$collabInfo"'/g' $file.tex
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

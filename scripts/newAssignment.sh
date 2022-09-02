#!/bin/bash

if [[ ! -z "$1" ]]; then
    mkdir $1
    cd $1
    cp -r $DOTFILES_DIR/files/assignmentsTemplate/* $PWD
    mv template.tex $1.tex

    courseName=$(echo $PWD | grep -Po "[A-Z]{4}[1-9]{3}.*/" | sed 's/\/.*//g' | sed 's/_/\ /g' | sed '0,/\ /{s/\ /\ -\ /}')
    termYear=$(echo $PWD | grep -Po "Y\d_.*/" | sed 's/\/.*//g' | sed 's/^.*_//g')\ $(echo $PWD | grep -Po "20\d\d")
    title=$(echo $1 | sed 's/_/\ /g')

    sed -i 's/COURSE_NAME/'"$courseName"'/g' $1.tex
    sed -i 's/TERM_YEAR/'"$termYear"'/g' $1.tex
    sed -i 's/TITLE/'"$title"'/g' $1.tex
fi

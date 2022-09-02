#!/bin/bash

if [[ ! -z "$1" ]]; then
    mkdir $1
    cd $1

    mkdir "src"
    cd "src"

    mainName=""
    if [[ -z "$2" ]]; then
        mainName="Main"
    else
        mainName=$2
    fi

    cp $DOTFILES_DIR/files/Java_standard.java $mainName.java
    sed -i "s/NAME/$mainName/g" $mainName.java
fi

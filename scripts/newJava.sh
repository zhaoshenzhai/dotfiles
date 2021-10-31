#!/bin/bash

Help()
{
    echo "Options:"
    echo "h | help   Prints this help"
    echo "n | name   Creates root directory Java~NAME, containing:"
    echo "   'src' directory"
    echo "      NAME.java"
}

while [ ! -z "$1" ]; do
    case "$1" in
        --name|-n)
            shift
            if [[ -z "$1" ]]; then
                echo "Please enter a nonempty name"
            else
                mkdir "Java~${1// /_}"
                cd "Java~${1// /_}"
                mkdir "src"
                cd "src"
                if [[ -z "$2" ]]; then
                    cp $HOME/Templates/Java/standard.txt "Main.java"
                    sed -i 's/NAME/Main/g' Main.java
                else
                    MAINNAME=${2// /}
                    cp $HOME/Templates/Java/standard.txt "$MAINNAME.java"
                    sed -i "s/NAME/$MAINNAME/g" $MAINNAME.java
                fi
            fi
            ;;
       --help|-h)
            Help
            ;;
        *);;
    esac
shift
done

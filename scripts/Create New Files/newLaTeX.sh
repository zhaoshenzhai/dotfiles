#!/bin/bash

Help()
{
    echo "Options:"
    echo "h | help   Prints this help"
    echo "n | name   Creates root directory NAME, containing:"
    echo "   NAME.tex"
    echo "   figures (directory)"
}

while [ ! -z "$1" ]; do
    case "$1" in
        --name|-n)
            shift
            if [[ -z "$1" ]]; then
                echo "Please enter a nonempty name"
            else
                NAME="${1// /_}"
                mkdir $NAME
                cd $NAME
                cp -r $HOME/.config/scripts/scriptFiles/LaTeX_standard/* $PWD
                mv main.tex "$NAME.tex"
            fi
            ;;
        --help|-h)
            Help
            ;;
        *)
            echo "Error: Invalid option"
            Help
            ;;
    esac
shift
done

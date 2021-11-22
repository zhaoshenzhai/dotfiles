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
                mkdir "${1// /_}"
                cd "${1// /_}"
                cp $HOME/.config/scripts/scriptFiles/LaTeX_standard "${1// /_}.tex"
                mkdir "figures"
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

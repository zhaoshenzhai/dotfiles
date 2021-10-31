#!/bin/bash

Help()
{
    echo "Options:"
    echo "h | help   Prints this help"
    echo "n | name   Creates root directory NAME, containing:"
    echo "   NAME.tex"
    echo "   figures"
    echo "      white.png"
    echo "d | docu   Creates root directory with only NAME.tex"
}

while [ ! -z "$1" ]; do
    case "$1" in
        --name|-n)
            shift
            if [[ -z "$1" ]]; then
                echo "Please enter a nonempty name"
            else
                mkdir "$1"
                cd "$1"
                cp $HOME/Templates/LaTeX/header.txt "${1// /\ }.tex"
                mkdir "figures"
                cp $HOME/Templates/LaTeX/figures/white.png figures
            fi
            ;;
        --docu|-d)
            shift
            if [[ -z "$1" ]]; then
                echo "Please enter a nonempty name"
            else
                mkdir "$1"
                cd "$1"
                cp $HOME/Templates/LaTeX/header.txt "${1// /\ }.tex"
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

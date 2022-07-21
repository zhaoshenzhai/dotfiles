#!/bin/bash

Help()
{
    echo "Options:"
    echo "h | help   Prints this help"
    echo "n | name   Takes 1 argument: [NAME]."
    echo "           Creates root directory C#~NAME, containing:"
    echo "              Program.cs"
}

while [ ! -z "$1" ]; do
    case "$1" in
        --name|-n)
            shift
            if [[ -z "$1" ]]; then
                echo "Please enter a nonempty name"
            else
                MAINNAME=${1// /}
                mkdir "C#~$MAINNAME"
                cd "C#~$MAINNAME"
                cp $HOME/.config/scripts/scriptFiles/CSharp_standard "Program.cs"
                sed -i "s/NAME/$MAINNAME/g" Program.cs
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

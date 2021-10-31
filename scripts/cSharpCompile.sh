#!/bin/bash

Help()
{
    echo "Options:"
    echo "h | help   Prints this help"
    echo "p | path   Provides script with path to Program.cs. Compiles the project and runs it."
}

while [ ! -z "$1" ]; do
    case "$1" in
        --path|-p)
            shift
            if [[ -z "$1" ]]; then
                echo "Invalid path"
            else
                mcs -out:$1/Program.exe $1/Program.cs
                mono $1/Program.exe
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

#!/bin/bash

file_path="/home/zhao/.config/scripts/scriptFiles/theme_fixed"

while [ ! -z "$1" ]; do
    case "$1" in
        --fixed|-f)
            shift
                echo "1" > $file_path 
            ;;
        --any|-a)
            shift
                echo "0" > $file_path
            ;;
        *)
            echo "Error: Invalid option"
            ;;
    esac
shift
done

#!/bin/bash

Help()
{
    echo "Options:"
    echo "h | help   Prints this help"
    echo "p | path   Provides script with path to the .java file with main. Compiles the project (multiple packages supported), locates the main .class, and runs it."
    echo "   REQUIREMENTS: Project should have the following structure:"
    echo "      Root directory: No spaces"
    echo "         'src' directory"
    echo "            Other folders and subfolders, containing .java files"
    echo "         Other folders (like 'res')"
    echo "   Automatically generates: (under Root)"
    echo "         'build' directory, containing all .class files"
    echo "         'source.txt' file containing paths to all .java files"
}

while [ ! -z "$1" ]; do
    case "$1" in
        --path|-p)
            shift
            if [[ -z "$1" ]]; then
                echo "Invalid path"
            else
                ROOT=$1
                echo $ROOT
                BASE=$(basename "$ROOT")
                echo $BASE
                while [[ ! "$BASE" =~ "~" ]]; do
                    ROOT=${ROOT%/*}
                    BASE=$(basename "$ROOT")
                done
                cd "$ROOT"
                find -name "*.java" > source.txt
                javac -d build @source.txt
                MAINPATH=`find . -type f -print | xargs grep "public static void main(String\[\] args)"`
                MAINPATH=${MAINPATH:5}
                while [[ $MAINPATH == *"."* ]]; do
                    MAINPATH=${MAINPATH%?}
                done
                MAINPATH="${MAINPATH////.}"
                MAINPATH=${MAINPATH:1}
                java -cp .:build:**/*.class $MAINPATH
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

#!/bin/bash

while [ ! -z "$1" ]; do
    case "$1" in
        --path|-p)
            shift
                if [[ -z "$1" ]]; then
                    echo "Invalid path"
                else
                    rootPath=$(echo $1 | sed 's/\/src\/.*$//g')
                    baseName=$(basename "$rootPath")
                    cd "$rootPath"

                    find -name "*.java" > src.txt
                    javac -d build @src.txt

                    mainPath=`find . -type f -print | xargs grep "public static void main(String\[\] args)"`
                    mainPath=${mainPath:5}
                    while [[ $mainPath == *"."* ]]; do
                        mainPath=${mainPath%?}
                    done
                    mainPath="${mainPath////.}"
                    mainPath=${mainPath:1}

                    java -cp .:build:**/*.class $mainPath
                fi
            ;;
    esac
shift
done

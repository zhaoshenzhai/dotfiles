#!/bin/bash

Help()
{
    echo "Options:"
    echo "h | help   Prints this help"
    echo "n | name   Takes 2 arguments: [NAME, MAINCLASS (Optional, default=NAME)]."
    echo "           Creates root directory Java~NAME, containing:"
    echo "              'src' directory"
    echo "                 MAINCLASS.java"
}

dirName=`date +"%d-%m-%Y_%H%M"`

cd ~/MathWiki/Images
mkdir $dirName
cd $dirName
touch image.tex


#!/bin/bash

dirName=`date +"%d-%m-%Y_%H%M"`

cd ~/MathWiki/Images
mkdir $dirName
cd $dirName
cp $HOME/MathWiki/imageTemplate.tex $PWD/image.tex

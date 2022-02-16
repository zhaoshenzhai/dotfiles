#!/bin/bash

cd ~/MathWiki/Images

total=`ls | wc -l`

current=1
for d in */ ; do
    cd $d
    pdflatex -shell-escape image.tex > /dev/null 2>&1 && pdfcrop image.pdf image.pdf > /dev/null 2>&1 && pdf2svg image.pdf image.svg
    echo "$d ($current/$total)"
    ((current=current+1))
    cd ..
done

rm *.log

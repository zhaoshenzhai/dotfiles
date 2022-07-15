#!/bin/bash

YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

path=$(echo "$1" | sed 's:Dropbox/Others:Downloads:g')
vid=$(echo "$2" | sed 's/\ /_/g' | sed 's/$/.mp4/g')
if [[ -f "$path/$vid" ]]; then
    echo -e "${GREEN}Video found, playing${NC}"
    sub=$(echo "$2" | sed 's/$/\.srt/g' | sed 's/\ /_/g')
    $(mpv "$path/$vid" --sub-file=$1/subs/$sub --title="$2")
    exit
fi

echo -e "${YELLOW}Video not found, attempting to find urls${NC}"

mainUrl=$(cat "$1/links.md" | grep "$2" | sed "s/$2\ //g")

curled=$(curl -s $mainUrl)
attempt=1
while [[ ! "$curled" ]]; do
    echo -ne "${YELLOW}Curling... (x$attempt)${NC}\r"
    sleep 1
    curled=$(curl -s $mainUrl)
    attempt=$(($attempt + 1))
done
if [[ ! "$attempt" == 1 ]]; then
    echo ""
fi

echo -e "${GREEN}Curled main page${NC}"

urls=$(echo "$curled" | grep -o -E "href=[\"'](.*)[\"']" | sed 's/href="//g' | sed 's/".*//g')
upStream=$(echo "$urls" | grep "https://upstream.to")
mixDrop=$(echo "$urls" | grep "https://mixdrop.co")
streamLare=$(echo "$urls" | grep "https://streamlare.com")
streamLareUrls=$(curl -s $streamLare | grep -o -E "href=[\"'](.*)[\"']" | sed 's/href="//g' | sed 's/".*//g')
slTube=$(echo "$streamLareUrls" | grep "https://sltube.org")

echo -e "${GREEN}Extracted links${NC}"

if [[ ! -z "$upStream" ]] && [[ ! $(curl -s $upStream | grep "File Not Found") ]]; then
    $(qutebrowser-profile --new 'N' $upStream &> /dev/null)
fi
if [[ ! -z "$mixDrop" ]] && [[ ! $(curl -s $mixDrop | grep "We can't") ]]; then
    $(qutebrowser-profile --new 'N' $mixDrop &> /dev/null)
fi
if [[ ! -z "$slTube" ]] && [[ ! $(curl -s $slTube | grep "File Not Found") ]]; then
    $(qutebrowser-profile --new 'N' $slTube &> /dev/null)
fi

echo -e "${GREEN}Opened browser${NC}"

attempt=1
while [[ ! -f "/home/zhao/Downloads/$vid.download" ]]; do
    echo -ne "${YELLOW}Waiting... (x$attempt)${NC}\r"
    sleep 1
    attempt=$(($attempt + 1))
done
echo ""

echo -e "${GREEN}File found, playing${NC}"

sub=$(echo "$2" | sed 's/$/\.srt/g' | sed 's/\ /_/g')

res=$(mpv "/home/zhao/Downloads/$vid.download" --sub-file=$1/subs/$sub --title="$2" | tee /dev/tty)
noFile=$(echo "$res" | grep -o "No such file or directory")
error=$(echo "$res" | grep -o "Errors when loading file")
attempt=1
while [[ "$fail" ]] || [[ "$error" ]]; do
    if [[ ! -f "/home/zhao/Downloads/$vid.download" ]] && [[ ! -f "/home/zhao/Downloads/$vid" ]]; then
        exit
    fi
    echo -ne "${YELLOW}Opening... (x$attempt)${NC}\r"
    sleep 1
    res=$(mpv "/home/zhao/Downloads/$vid.download" --sub-file=$1/subs/$sub --title="$2" | tee /dev/tty)
    noFile=$(echo "$res" | grep -o "No such file or directory")
    error=$(echo "$res" | grep -o "Errors when loading file")
    attempt=$(($attempt + 1))
done

rm "/home/zhao/Downloads/$vid.download"
if [[ -f "/home/zhao/Downloads/$vid" ]]; then
    mv "/home/zhao/Downloads/$vid" "$path"
fi
exit

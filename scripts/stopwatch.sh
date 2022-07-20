#!/bin/bash

YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

stopwatch() {
    keyPress=""
    while [[ $keyPress != s ]] && [[ $keyPress != q ]] && [[ $keyPress != p ]]; do
        now=$(date +%s)
        totalTime=$(date -u --date @$(($now - $1 - $pauseElapsed)) +%H:%M:%S)

        if [[ ! -z $2 ]]; then
            splitTime=$(date -u --date @$(($now - $2 - $pauseElapsedSplit)) +%H:%M:%S)
        else
            splitTime=$totalTime
        fi

        echo -ne "${GREEN}Split time: $splitTime | Total time: $totalTime${NC}\r"

        keyPress=$(cat -v)
        sleep 0.01
    done

    if [[ $keyPress == p ]]; then
        pause
    elif [[ $keyPress == q ]]; then
        printf "\n"
    fi
}

pause() {
    pauseStart=$(date +%s)
    keyPress=""
    echo -ne "${YELLOW}Split time: $splitTime | Total time: $totalTime${NC}\r"
    while [[ $keyPress != p ]] && [[ $keyPress != q ]]; do
        keyPress=$(cat -v)
        sleep 0.01
    done
    pauseEnd=$(date +%s)

    if [[ $keyPress == p ]]; then
        pauseElapsed=$(($pauseElapsed + $pauseEnd - $pauseStart))
        pauseElapsedSplit=$(($pauseEnd - $pauseStart))
        stopwatch $START $SPLIT
    elif [[ $keyPress == q ]]; then
        printf "\n"
    fi
}

repeat="Y"
while [[ $repeat == Y ]]; do
    echo -e "${CYAN}Press 'p' to pause/resume\n      's' to split\n      'q' to quit\n${NC}"
    read -n 1 -ep "$(echo -e "${CYAN}Press 'Enter' or 'Space' to start:${NC}") " input
    if [[ $input == q ]]; then
        exit
    fi

    while [[ ! -z $input ]]; do
        clear 
        echo -e "${CYAN}Press 'p' to pause/resume\n      's' to split\n      'q' to quit\n${NC}"
        read -n 1 -ep "$(echo -e "${CYAN}Press 'Enter' or 'Space' to start:${NC}") " input
        if [[ $input == q ]]; then
            exit
        fi
    done
    printf "\n"

    if [ -t 0 ]; then
        SAVED_STTY="`stty --save`"
        stty -echo -icanon -icrnl time 0 min 0
    fi

    START=$(date +%s)
    pauseElapsed=0

    stopwatch $START
    splitTimes=$totalTime   

    while [[ $keyPress != q ]]; do
        SPLIT=$(date +%s)
        pauseElapsedSplit=0

        stopwatch $START $SPLIT
        splitTimes="$splitTimes $splitTime"
    done

    count=1
    while [[ "$splitTimes" != "" ]]; do
        echo -e "${PURPLE}Split #$count: $(echo "$splitTimes" | sed 's/\ .*//g')${NC}"
        if [[ $(grep " " <<< "$splitTimes") ]]; then
            splitTimes=$(echo "$splitTimes" | sed 's/^..:..:..\ //g')
        else
            splitTimes=""
        fi
        count=$((++count))
    done
    printf "\n"

    if [ -t 0 ]; then stty "$SAVED_STTY"; fi   

    read -n 1 -ep "$(echo -e ${CYAN}"Press [Y] to return, exiting otherwise...${NC} ")" repeat
    if [[ -z "$repeat" ]]; then
        repeat="Y"
    fi
    if [[ "$repeat" == "Y" ]]; then
        clear
    else
        exit
    fi
done

#!/bin/bash

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

        echo -ne "${GREEN}Split #$splitCount: $splitTime | Total: $totalTime${NC}\r"

        keyPress=$(cat -v)
        sleep 0.1
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
    echo -ne "${YELLOW}Split #$splitCount: $splitTime | Total: $totalTime${NC}\r"
    while [[ $keyPress != p ]] && [[ $keyPress != q ]]; do
        keyPress=$(cat -v)
        sleep 0.1
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
    echo -e "${CYAN}Press [p] to pause/resume\n      [s] to split\n      [q] to quit\n${NC}"
    read -n 1 -ep "$(echo -e "${CYAN}Press [Enter] or [Space] to start:${NC}") " input
    if [[ $input == q ]]; then
        exit
    fi

    while [[ ! -z $input ]]; do
        clear 
        echo -e "${CYAN}Press [p] to pause/resume\n      [s] to split\n      [q] to quit\n${NC}"
        read -n 1 -ep "$(echo -e "${CYAN}Press [Enter] or [Space] to start:${NC}") " input
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
    splitCount=1

    stopwatch $START
    splitTimes=$totalTime   

    while [[ $keyPress != q ]]; do
        SPLIT=$(date +%s)
        pauseElapsedSplit=0
        splitCount=$((++splitCount))

        stopwatch $START $SPLIT
        splitTimes="$splitTimes $splitTime"
    done

    cd ~/Downloads
    fileName="Stopwatch_$(date +"%Y-%m-%d_%H%M%S")"
    touch $fileName
    echo "Total time: $totalTime" >> $fileName
    if [[ $splitCount -gt 1 ]]; then
        count=1
        echo "" >> $fileName
        echo ""
        while [[ "$splitTimes" != "" ]]; do
            echo "    Split #$count: $(echo "$splitTimes" | sed 's/\ .*//g')" >> $fileName
            echo -e "${PURPLE}Split #$count: $(echo "$splitTimes" | sed 's/\ .*//g')${NC}"
            if [[ $(grep " " <<< "$splitTimes") ]]; then
                splitTimes=$(echo "$splitTimes" | sed 's/^..:..:..\ //g')
            else
                splitTimes=""
            fi
            count=$((++count))
        done
    fi

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

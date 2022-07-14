#!/bin/bash

RAW=`pamixer --list-sinks`

LINES=`echo "$RAW" | wc -l`

VOLUME=""
MUTE=true

if [ "$LINES" -eq 2 ]; then
    SINK=`echo "$RAW" | sed -n 2p`
    SPEAKER=${SINK%%\ *}
    VOLUME=`pamixer --sink "$SPEAKER" --get-volume`
    MUTE=`pamixer --sink "$SPEAKER" --get-mute`
elif [ "$LINES" -eq 3 ]; then
    SINK=`echo "$RAW" | sed -n 3p`
    HEADPHONE=${SINK%%\ *}
    VOLUME=`pamixer --sink "$HEADPHONE" --get-volume`
    MUTE=`pamixer --sink "$HEADPHONE" --get-mute`
fi

while [ ! -z "$1" ]; do
    case "$1" in
        --toggle|-t)
            shift
            `pamixer -t`
            ;;
        --play/pause|-p)
            shift
            `playerctl -p spotify play-pause`
            ;;
        --next|-n)
            shift
            `playerctl -p spotify next`
            ;;
        --previous|-b)
            shift
            `playerctl -p spotify previous`
            ;;
        --increase|-i)
            shift
            if [[ -z "$1" ]]; then
                echo "Please choose an increment"
            else
                if [ "$MUTE" = true ]; then
                    `pamixer -u`
                fi
                VOLUME=$((VOLUME + $1))
                `pamixer --set-volume $VOLUME`
            fi
            ;;
        --decrease|-d)
            shift
            if [[ -z "$1" ]]; then
                echo "Please choose an increment"
            else
                if [ "$MUTE" = true ]; then
                    `pamixer -u`
                fi
                VOLUME=$((VOLUME - $1))
                echo $VOLUME
                `pamixer --set-volume $VOLUME`
            fi
            ;;
        --connect1|-c1)
            shift
            `bluetoothctl power on`
            `bluetoothctl connect 88:D0:39:9F:C9:4B`
            ;;
        --connect2|-c2)
            shift
            `bluetoothctl power on`
            `bluetoothctl connect E8:07:BF:CB:CD:1A`
            ;;
        --disconnect1|-d1)
            shift
            `bluetoothctl disconnect 88:D0:39:9F:C9:4B`
            `bluetoothctl power off`
            `playerctl -p spotify pause`
            ;;
        --disconnect2|-d2)
            shift
            `bluetoothctl disconnect E8:07:BF:CB:CD:1A`
            `bluetoothctl power off`
            `playerctl -p spotify pause`
            ;;
    esac
shift
done

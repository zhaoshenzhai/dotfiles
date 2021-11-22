#!/bin/bash

Help()
{
    echo "Options:"
    echo "h | Prints this help"
    echo "t | Toggles Mute/Unmute"
    echo "i | Increases Volume"
    echo "d | Decreases Volume"
}

RAW=`pamixer --list-sink`

LINES=`echo "$RAW" | wc -l`

VOLUME=""

if [ "$LINES" -eq 2 ]; then
    SINK=`echo "$RAW" | sed -n 2p`
    SPEAKER=${SINK:0:1}
    VOLUME=`pamixer --sink "$SPEAKER" --get-volume`
elif [ "$LINES" -eq 3 ]; then
    SINK=`echo "$RAW" | sed -n 3p`
    HEADPHONE=${SINK:0:1}
    VOLUME=`pamixer --sink "$HEADPHONE" --get-volume`
fi

while [ ! -z "$1" ]; do
    case "$1" in
        --toggle|-t)
            shift
            `pamixer -t`
            ;;
        --increase|-i)
            shift
            if [[ -z "$1" ]]; then
                echo "Please choose an increment"
            else
                VOLUME=$((VOLUME + $1))
                `pamixer --set-volume $VOLUME`
            fi
            ;;
        --decrease|-d)
            shift
            if [[ -z "$1" ]]; then
                echo "Please choose an increment"
            else
                VOLUME=$((VOLUME - $1))
                `pamixer --set-volume $VOLUME`
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

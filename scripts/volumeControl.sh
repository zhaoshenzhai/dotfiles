#!/bin/bash

Help()
{
    echo "Options:"
    echo "h | Prints this help"
    echo "t | Toggles Mute/Unmute"
    echo "i | Increases Volume"
    echo "d | Decreases Volume"
}

NUMLINES=$(pamixer --list-sink | sed -n 'p;$=' |& tail -1)

VOLUME=""

if [ "$NUMLINES" -eq 2 ]; then
    SINK=`pamixer --list-sinks | sed -n 2p`
    SPEAKER=${SINK:0:1}
    VOLUME=`pamixer --sink "$SPEAKER" --get-volume`
elif [ "$NUMLINES" -eq 3 ]; then
    SINK=`pamixer --list-sinks | sed -n 3p`
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

#!/bin/bash

Help()
{
    echo "Options:"
    echo "h | Prints this help"
    echo "t | Toggles Mute/Unmute"
    echo "i | Increases Volume"
    echo "d | Decreases Volume"
    echo "p | Play/pause"
}

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
        --next)
            shift
            `playerctl -p spotify next`
            ;;
        --previous)
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

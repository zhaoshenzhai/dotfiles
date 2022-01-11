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
            `dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause`
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

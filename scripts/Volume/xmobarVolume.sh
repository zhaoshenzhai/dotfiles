#!/bin/bash

RAW=`pamixer --list-sink`
LINES=`echo "$RAW" | wc -l`

if [ "$LINES" -eq 2 ]; then
    SINK=`echo "$RAW" | sed -n 2p`
    SPEAKER=${SINK%%\ *}
    MUTE=`pamixer --sink "$SPEAKER" --get-mute`
    if [ "$MUTE" = true ]; then
        printf "%s %s" "<fn=2> </fn>" "Muted"
    else
        SPEAKER_VOL=`pamixer --sink "$SPEAKER" --get-volume-human`
        printf "%s %s" "<fn=2> </fn>" $SPEAKER_VOL
    fi
elif [ "$LINES" -eq 3 ]; then
    SINK=`echo "$RAW" | sed -n 3p`
    HEADPHONE=${SINK%%\ *}
    MUTE=`pamixer --sink "$HEADPHONE" --get-mute`
    if [ "$MUTE" = true ]; then
        printf "%s %s" "<fn=2> </fn>" "Muted"
    else
        HEADPHONE_VOL=`pamixer --sink "$HEADPHONE" --get-volume-human`
        printf "%s %s" "<fn=2> </fn>" $HEADPHONE_VOL
    fi
fi

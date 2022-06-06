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
    HEADPHONE_BAT=`bluetoothctl info | sed -n 19p | sed -E 's/(.*\()//g' | sed 's/.$//'`
    if [ "$MUTE" = true ]; then
        printf "%s %s | %s" "<fn=2> </fn>" "Muted" $HEADPHONE_BAT"%"
    else
        HEADPHONE_VOL=`pamixer --sink "$HEADPHONE" --get-volume-human`
        printf "%s %s | %s" "<fn=2> </fn>" $HEADPHONE_VOL $HEADPHONE_BAT"%"
    fi
fi

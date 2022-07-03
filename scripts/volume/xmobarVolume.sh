#!/bin/bash

RAW=`pamixer --list-sinks`
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
    BLUETOOTHINFO=`bluetoothctl info | tail -n1`
    if [[ `echo "$BLUETOOTHINFO" | cut -c2` == "B" ]]; then
        HEADPHONE_BAT=`echo "$BLUETOOTHINFO" | sed -E 's/(.*\()//g' | sed 's/.$//'`
    else
        HEADPHONE_BAT="--"
    fi

    if [ "$MUTE" = true ]; then
        printf "%s %s | %s" "<fn=2> </fn>" "Muted" $HEADPHONE_BAT"%"
    else
        HEADPHONE_VOL=`pamixer --sink "$HEADPHONE" --get-volume-human`
        printf "%s %s | %s" "<fn=2> </fn>" $HEADPHONE_VOL $HEADPHONE_BAT"%"
    fi
fi

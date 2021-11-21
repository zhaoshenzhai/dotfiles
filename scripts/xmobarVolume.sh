#!/bin/bash
NUMLINES=$(pamixer --list-sink | sed -n 'p;$=' |& tail -1)

SPEAKER_VOL=""
HEADPHONE_VOL=""

VOLUME=""

if [ "$NUMLINES" -eq 2 ]; then
    SINK=`pamixer --list-sinks | sed -n 2p`
    SPEAKER=${SINK:0:1}
    SPEAKER_VOL=`pamixer --sink "$SPEAKER" --get-volume-human`

    VOLUME=`pamixer --sink "$SPEAKER" --get-volume`
    printf "%s %s" "<fn=2> </fn>" $SPEAKER_VOL
elif [ "$NUMLINES" -eq 3 ]; then
    SINK=`pamixer --list-sinks | sed -n 3p`
    HEADPHONE=${SINK:0:1}
    HEADPHONE_VOL=`pamixer --sink "$HEADPHONE" --get-volume-human`

    VOLUME=`pamixer --sink "$HEADPHONE" --get-volume`
    printf "%s %s" "<fn=2> </fn>" $HEADPHONE_VOL
fi

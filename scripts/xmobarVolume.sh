#!/bin/bash
NUMLINES=$(pamixer --list-sink | sed -n 'p;$=' |& tail -1)

SPEAKER_VOL=""
HEADPHONE_VOL=""

if [ "$NUMLINES" -eq 2 ]; then
    SINK=`pamixer --list-sinks | sed -n 2p`
    SPEAKER=${SINK:0:1}
    SPEAKER_VOL=`pamixer --sink "$SPEAKER" --get-volume-human`
    printf "%s %s" "<fn=2> </fn>" $SPEAKER_VOL
elif [ "$NUMLINES" -eq 3 ]; then
    SINK=`pamixer --list-sinks | sed -n 3p`
    HEADPHONE=${SINK:0:1}
    HEADPHONE_VOL=`pamixer --sink "$HEADPHONE" --get-volume-human`
    printf "%s %s" "<fn=2> </fn>" $HEADPHONE_VOL
fi

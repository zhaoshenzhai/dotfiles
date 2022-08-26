#!/bin/bash

raw=$(pamixer --list-sinks)
sinks="Sinks:"
while IFS= read -r sink; do
    if [[ -z $(echo "$sink" | grep "HDMI") ]] && [[ -z $(echo "$sink" | grep "Sinks:") ]]; then
        sinks="$sinks\n$sink"
    fi
done <<< "$raw"
lines=`echo -e "$sinks" | wc -l`

if [ "$lines" -eq 2 ]; then
    sink=`echo -e "$sinks" | sed -n 2p`
    speaker=${sink%%\ *}
    mute=`pamixer --sink "$speaker" --get-mute`

    if [ "$mute" = true ]; then
        printf "%s %s" "<fn=2> </fn>" "muted"
    else
        speakerVol=`pamixer --sink "$speaker" --get-volume-human`
        printf "%s %s" "<fn=2> </fn>" $speakerVol
    fi
elif [ "$lines" -eq 3 ]; then
    sink=`echo -e "$sinks" | sed -n 3p`
    headphone=${sink%%\ *}
    mute=`pamixer --sink "$headphone" --get-mute`

    if [ "$mute" = true ]; then
        printf "%s %s | %s" "<fn=2> </fn>" "muted"
    else
        headphoneVol=`pamixer --sink "$headphone" --get-volume-human`
        printf "%s %s" "<fn=2> </fn>" $headphoneVol
    fi
fi

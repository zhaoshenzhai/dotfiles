#!/bin/bash

raw=$(pamixer --list-sinks)
sinks="Sinks:"
while IFS= read -r sink; do
    if [[ -z $(echo "$sink" | grep "HDMI") ]] && [[ -z $(echo "$sink" | grep "Pro ") ]] && [[ -z $(echo "$sink" | grep "Controller") ]] && [[ -z $(echo "$sink" | grep "Sinks:") ]]; then
        sinks="$sinks\n$sink"
    fi
done <<< "$raw"
lines=`echo -e "$sinks" | wc -l`

volume=""
mute=true

if [ "$lines" -eq 2 ]; then
    sink=`echo -e "$sinks" | sed -n 2p`
    speaker=${sink%%\ *}
    volume=`pamixer --sink "$speaker" --get-volume`
    mute=`pamixer --sink "$speaker" --get-mute`
elif [ "$lines" -eq 3 ]; then
    sink=`echo -e "$sinks" | sed -n 3p`
    headphone=${sink%%\ *}
    volume=`pamixer --sink "$headphone" --get-volume`
    mute=`pamixer --sink "$headphone" --get-mute`
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
        --next|-n)
            shift
            `playerctl -p spotify next`
            ;;
        --previous|-b)
            shift
            `playerctl -p spotify previous`
            ;;
        --increase|-i)
            shift
            if [[ -z "$1" ]]; then
                echo "Please choose an increment"
            else
                if [ "$mute" = true ]; then
                    `pamixer -u`
                fi
                volume=$((volume + $1))
                `pamixer --set-volume $volume`
            fi
            ;;
        --decrease|-d)
            shift
            if [[ -z "$1" ]]; then
                echo "Please choose an increment"
            else
                if [ "$mute" = true ]; then
                    `pamixer -u`
                fi
                volume=$((volume - $1))
                echo $volume
                `pamixer --set-volume $volume`
            fi
            ;;
        --connect|-c)
            shift
            `bluetoothctl power on`
            `bluetoothctl connect 50:C2:75:90:15:26`
            ;;
        --disconnect|-x)
            shift
            `bluetoothctl disconnect 50:C2:75:90:15:26`
            `bluetoothctl power off`
            `playerctl -p spotify pause`
            ;;
    esac
shift
done

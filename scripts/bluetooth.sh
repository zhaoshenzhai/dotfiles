#!/bin/bash

while [ ! -z "$1" ]; do
    case "$1" in
        --connect|-c)
            shift
            `bluetoothctl connect 88:D0:39:9F:C9:4B`
            `bluetoothctl connect E8:07:BF:CB:CD:1A`
            ;;
        --disconnect|-d)
            shift
            `bluetoothctl disconnect 88:D0:39:9F:C9:4B`
            `bluetoothctl disconnect E8:07:BF:CB:CD:1A`
            `playerctl -p spotify pause`
            ;;
    esac
shift
done

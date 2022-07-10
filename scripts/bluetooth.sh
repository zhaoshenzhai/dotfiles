#!/bin/bash

while [ ! -z "$1" ]; do
    case "$1" in
        --connect1|-c1)
            shift
            `bluetoothctl connect 88:D0:39:9F:C9:4B`
            ;;
        --connect2|-c2)
            shift
            `bluetoothctl connect E8:07:BF:CB:CD:1A`
            ;;
        --disconnect1|-d1)
            shift
            `bluetoothctl disconnect 88:D0:39:9F:C9:4B`
            `playerctl -p spotify pause`
            ;;
        --disconnect2|-d2)
            shift
            `bluetoothctl disconnect E8:07:BF:CB:CD:1A`
            `playerctl -p spotify pause`
            ;;
    esac
shift
done

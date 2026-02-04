#!/bin/bash

if [ "$SENDER" = "front_app_switched" ]; then
    if [ "$INFO" = ".zathura-wrapped" ]; then
        INFO=zathura
    fi

    sketchybar --set $NAME label="$INFO" icon="$($HOME/.config/sketchybar/plugins/icon_map.sh "$INFO")"
fi

#!/bin/bash

if [ "$SENDER" = "front_app_switched" ]; then
    if [ "$INFO" = ".zathura-wrapped" ]; then
        INFO=zathura
    fi

    ICON="$($HOME/.config/sketchybar/plugins/icon_map.sh "$INFO")"
    sketchybar --set $NAME label="$INFO" icon=$ICON icon.font="sketchybar-app-font:Regular:16.0"
fi

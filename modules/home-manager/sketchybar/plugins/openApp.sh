#!/bin/bash

if [ "$SENDER" = "front_app_switched" ]; then
    if [ "$INFO" = ".zathura-wrapped" ]; then
        INFO=zathura
    fi

    ICON="$($HOME/.config/sketchybar/plugins/icon_map.sh "$INFO")"
    if [[ $ICON = :* ]]; then
        sketchybar --set $NAME label="$INFO" icon="$ICON"
    else
        sketchybar --set $NAME label="$INFO" icon="$ICON" icon.font="Font Awesome 7 Free:Solid:14.0"
    fi

fi

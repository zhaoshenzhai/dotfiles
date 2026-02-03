#!/bin/bash

if [ "$SENDER" = "front_app_switched" ]; then
    sketchybar --set $NAME label="$INFO" icon="$($HOME/.config/sketchybar/plugins/icon_map.sh "$INFO")"
fi

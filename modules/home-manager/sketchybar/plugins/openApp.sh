#!/usr/bin/env bash

source "$HOME/.config/sketchybar/plugins/iconMap.sh" > /dev/null

if [ "$SENDER" = "front_app_switched" ]; then
    if [ "$INFO" = ".zathura-wrapped" ]; then
        INFO=zathura
    fi

    iconMap "$INFO"
    sketchybar --animate tanh 8 --set "$NAME" label="$INFO" icon="$icon_result" icon.font="sketchybar-app-font:Regular:16.0"
fi

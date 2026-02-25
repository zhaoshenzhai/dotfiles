#!/usr/bin/env bash

source "$HOME/.config/sketchybar/plugins/iconMap.sh" > /dev/null

if [ "$SENDER" = "front_app_switched" ]; then
    iconMap "$INFO"
    sketchybar --animate tanh 8 --set "$NAME" label="$INFO" icon="$icon_result" icon.font="sketchybar-app-font:Regular:16.0"

    sleep 0.1
    sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE
fi

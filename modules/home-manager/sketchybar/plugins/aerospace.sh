#!/usr/bin/env bash

ICON_MAP="$HOME/.config/sketchybar/plugins/icon_map.sh"

if [ -z "$FOCUSED_WORKSPACE" ]; then
    FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)
fi

OCCUPIED_WORKSPACES=$(aerospace list-workspaces --monitor all --empty no)

ARGS=()
for sid in $(aerospace list-workspaces --all); do
    apps=$(aerospace list-windows --workspace "$sid" --format "%{app-name}" | sort -u)
    icon_strip=""
    if [ "${apps}" != "" ]; then
        while IFS= read -r app; do
            if [ "$app" = ".zathura-wrapped" ]; then
                app=zathura
            fi
            icon_strip+=" $("$ICON_MAP" "$app")"
        done <<< "$apps"
        ARGS+=(--set "space.$sid" icon="$icon_strip" icon.padding_left=5 icon.padding_right=0 label.padding_left=10)
    else
        ARGS+=(--set "space.$sid" icon="" icon.drawing=off icon.padding_left=0 icon.padding_right=0 label.padding_left=5)
    fi

    if [ "$sid" = "$FOCUSED_WORKSPACE" ]; then
        ARGS+=(--set "space.$sid" drawing=on label.drawing=on icon.drawing=on background.drawing=on)
    elif echo "$OCCUPIED_WORKSPACES" | grep -q "$sid"; then
        ARGS+=(--set "space.$sid" drawing=on label.drawing=on icon.drawing=on background.drawing=off)
    else
        ARGS+=(--set "space.$sid" drawing=off)
    fi
done

sketchybar "${ARGS[@]}"

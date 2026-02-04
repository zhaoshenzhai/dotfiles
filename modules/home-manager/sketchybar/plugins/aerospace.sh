#!/bin/bash

if [ -z "$FOCUSED_WORKSPACE" ]; then
    FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)
fi

OCCUPIED_WORKSPACES=$(aerospace list-workspaces --monitor all --empty no)

ARGS=()
for sid in $(aerospace list-workspaces --all); do
    if [ "$sid" = "$FOCUSED_WORKSPACE" ]; then
        ARGS+=(--set "space.$sid" drawing=on label.drawing=on background.drawing=on)
    elif echo "$OCCUPIED_WORKSPACES" | grep -q "$sid"; then
        ARGS+=(--set "space.$sid" drawing=on label.drawing=on background.drawing=off)
    else
        ARGS+=(--set "space.$sid" drawing=off)
    fi
done

sketchybar "${ARGS[@]}"

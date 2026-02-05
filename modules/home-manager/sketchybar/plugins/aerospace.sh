#!/usr/bin/env bash

source "$HOME/.config/sketchybar/plugins/icon_map.sh" > /dev/null

if [ -z "$FOCUSED_WORKSPACE" ]; then
    FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)
fi

WINDOWS_DATA=$(aerospace list-windows --all --format "%{workspace}|%{app-name}")
ALL_WORKSPACES=$(aerospace list-workspaces --all)

ARGS=()

while IFS= read -r sid; do
    workspace_apps=$(echo "$WINDOWS_DATA" | grep "^$sid|" | cut -d'|' -f2 | sort -u)

    iconStrip=""
    if [ -n "$workspace_apps" ]; then
        while IFS= read -r app; do
            if [ -n "$app" ]; then
                if [ "$app" = ".zathura-wrapped" ]; then
                    app=zathura
                fi

                icon_map "$app"
                iconStrip+="$icon_result"
            fi
        done <<< "$workspace_apps"

        iconPaddingLeft=10
        iconDrawing="on"
        labelPaddingLeft=5
        is_occupied=true
    else
        iconStrip=""
        iconPaddingLeft=0
        iconDrawing="off"
        labelPaddingLeft=10
        is_occupied=false
    fi

    if [ "$sid" = "$FOCUSED_WORKSPACE" ]; then
        drawing="on"
        bgDrawing="on"
    elif [ "$is_occupied" = true ]; then
        drawing="on"
        bgDrawing="off"
    else
        drawing="off"
        bgDrawing="off"
    fi

    if [[ "$sid" =~ ^[0-9]$ ]]; then
        labelDrawing="$drawing"
        labelPaddingRight=10
        iconPaddingRight=0
    else
        labelDrawing="off"
        labelPaddingLeft=0
        labelPaddingRight=0
        iconPaddingRight="$iconPaddingLeft"
    fi

    ARGS+=(--set "space.$sid"                    \
        drawing="$drawing"                       \
        background.drawing="$bgDrawing"          \
        label.drawing="$labelDrawing"            \
        label.padding_left="$labelPaddingLeft"   \
        label.padding_right="$labelPaddingRight" \
        icon.drawing="$iconDrawing"              \
        icon.padding_left="$iconPaddingLeft"     \
        icon.padding_right="$iconPaddingRight"   \
        icon="$iconStrip")

done <<< "$ALL_WORKSPACES"

sketchybar "${ARGS[@]}"

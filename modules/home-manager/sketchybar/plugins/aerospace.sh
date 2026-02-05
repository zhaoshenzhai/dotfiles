#!/usr/bin/env bash

ICON_MAP="$HOME/.config/sketchybar/plugins/icon_map.sh"

if [ -z "$FOCUSED_WORKSPACE" ]; then
    FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)
fi

OCCUPIED_WORKSPACES=$(aerospace list-workspaces --monitor all --empty no)

ARGS=()
for sid in $(aerospace list-workspaces --all); do
    apps=$(aerospace list-windows --workspace "$sid" --format "%{app-name}" | sort -u)
    iconStrip=""

    if [ "${apps}" != "" ]; then
        while IFS= read -r app; do
            if [ "$app" = ".zathura-wrapped" ]; then
                app=zathura
            fi
            iconStrip+="$("$ICON_MAP" "$app")"
        done <<< "$apps"
        iconPaddingLeft=10
        iconDrawing="on"
        labelPaddingLeft=5
    else
        iconStrip=""
        iconPaddingLeft=0
        iconDrawing="off"
        labelPaddingLeft=10
    fi

    if [ "$sid" = "$FOCUSED_WORKSPACE" ]; then
        drawing="on"
        bgDrawing="on"
    elif echo "$OCCUPIED_WORKSPACES" | grep -q "$sid"; then
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
done

sketchybar "${ARGS[@]}"

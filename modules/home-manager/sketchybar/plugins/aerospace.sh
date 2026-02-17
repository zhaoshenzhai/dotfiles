#!/usr/bin/env bash

source "$HOME/.config/sketchybar/plugins/icon_map.sh" > /dev/null
source "$HOME/.config/sketchybar/colors.sh" > /dev/null

if [ -z "$FOCUSED_WORKSPACE" ]; then
    FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)
fi

WINDOWS_DATA=$(aerospace list-windows --all --format "%{workspace}|%{app-name}")
ALL_WORKSPACES=$(aerospace list-workspaces --all)

ARGS=()

while IFS= read -r sid; do
    workspace_apps=$(echo "$WINDOWS_DATA" | grep "^$sid|" | cut -d'|' -f2 | sort -u)

    iconStrip=""
    if [[ -n "$workspace_apps" ]]; then
        while IFS= read -r app; do
            if [[ -n "$app" ]]; then
                if [[ "$app" = ".zathura-wrapped" ]]; then
                    app=zathura
                fi

                icon_map "$app"
                iconStrip+="$icon_result"
            fi
        done <<< "$workspace_apps"

        isOccupied=true
    else
        isOccupied=false
    fi

    if [[ "$sid" = "$FOCUSED_WORKSPACE" ]] || [[ "$isOccupied" = true ]]; then
        if [[ "$sid" =~ ^[0-9]$ ]]; then
            iconPaddingLeft=10
            iconPaddingRight=5
            labelPaddingLeft=5
            labelPaddingRight=10
        else
            iconPaddingLeft=10
            iconPaddingRight=10
            labelPaddingLeft=0
            labelPaddingRight=0
        fi

        if [[ "$isOccupied" = false ]]; then
            iconPaddingLeft=0
            iconPaddingRight=0
            labelPaddingLeft=10
            labelPaddingRight=10
        fi
    else
        iconPaddingLeft=0
        iconPaddingRight=0
        labelPaddingLeft=0
        labelPaddingRight=0
    fi

    if [[ "$sid" = "$FOCUSED_WORKSPACE" ]]; then
        bgColor="$BAR_COLOR"
        borderColor="$BORDER_COLOR"
        iconColor="$ICON_COLOR"
        labelColor="$LABEL_COLOR"
    elif [[ "$isOccupied" = true ]]; then
        bgColor="$TRANSPARENT"
        borderColor="$TRANSPARENT"
        iconColor="$ICON_COLOR"
        labelColor="$LABEL_COLOR"
    else
        bgColor="$TRANSPARENT"
        borderColor="$TRANSPARENT"
        iconColor="$TRANSPARENT"
        labelColor="$TRANSPARENT"
    fi

    ARGS+=(
        --animate tanh 40                             \
        --set "space.$sid"                            \
        background.color="$bgColor"                   \
        background.border_color="$borderColor"        \
        icon="$iconStrip"                             \
        icon.color="$iconColor"                       \
        icon.padding_left="$iconPaddingLeft"          \
        icon.padding_right="$iconPaddingRight"        \
        label.color="$labelColor"                     \
        label.padding_left="$labelPaddingLeft"        \
        label.padding_right="$labelPaddingRight"      )

done <<< "$ALL_WORKSPACES"

sketchybar "${ARGS[@]}"

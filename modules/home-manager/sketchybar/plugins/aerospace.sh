#!/usr/bin/env bash

source "$HOME/.config/sketchybar/plugins/iconMap.sh" > /dev/null
source "$HOME/.config/sketchybar/colors.sh" > /dev/null

if [ -z "$FOCUSED_WORKSPACE" ]; then
    FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)
fi

DATA=$(aerospace list-windows --all --format "%{workspace}|%{app-name}" | sort | uniq)

while IFS='|' read -r sid app; do
    if [[ -z "$sid" || -z "$app" ]]; then continue; fi
    iconMap "$app"

    eval "current_strip=\${ICON_STRIP_${sid}}"
    printf -v "ICON_STRIP_${sid}" "%s" "${current_strip}${icon_result}"
done <<< "$DATA"

ALL_WORKSPACES=$(aerospace list-workspaces --all)
ARGS=()

while IFS= read -r sid; do
    eval "iconStrip=\${ICON_STRIP_${sid}}"
    iconStrip="${iconStrip#" "}"

    if [[ -n "$iconStrip" ]]; then
        isOccupied=true
    else
        isOccupied=false
    fi

    if [[ "$sid" = "$FOCUSED_WORKSPACE" ]] || [[ "$isOccupied" = true ]]; then
        if [[ "$sid" =~ ^[1-9]$ ]]; then
            iconPaddingLeft=10
            iconPaddingRight=5
            labelPaddingLeft=5
            labelPaddingRight=10
        else
            iconPaddingLeft=8
            iconPaddingRight=6
            labelPaddingLeft=0
            labelPaddingRight=0
        fi

        if [[ "$isOccupied" = false ]]; then
            iconPaddingLeft=0
            iconPaddingRight=0
            labelPaddingLeft=10
            labelPaddingRight=10
        fi
        backgroundPadding=2
    else
        iconPaddingLeft=0
        iconPaddingRight=0
        labelPaddingLeft=0
        labelPaddingRight=0
        backgroundPadding=0
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
        --animate tanh 8                              \
        --set "space.$sid"                            \
        background.color="$bgColor"                   \
        background.border_color="$borderColor"        \
        background.padding_left="$backgroundPadding"  \
        background.padding_right="$backgroundPadding" \
        icon="$iconStrip"                             \
        icon.color="$iconColor"                       \
        icon.padding_left="$iconPaddingLeft"          \
        icon.padding_right="$iconPaddingRight"        \
        label.color="$labelColor"                     \
        label.padding_left="$labelPaddingLeft"        \
        label.padding_right="$labelPaddingRight"      )

done <<< "$ALL_WORKSPACES"

sketchybar "${ARGS[@]}"

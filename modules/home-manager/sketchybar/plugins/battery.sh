#!/usr/bin/env bash

source "$HOME/.config/sketchybar/colors.sh"

PERCENTAGE=$(pmset -g batt | grep -o "[0-9]\{1,3\}%" | cut -d% -f1)
CHARGING=$(pmset -g batt | grep 'AC Power')

if [ "$PERCENTAGE" = "" ]; then
    exit 0
fi

COLOR=$WHITE

if [ -n "$CHARGING" ]; then
    if [ "$PERCENTAGE" = "100" ]; then
        ICON="􀛨"
        COLOR=$WHITE
    else
        ICON="􀢋"
        COLOR=$GREEN
    fi
else
    case ${PERCENTAGE} in
        9[0-9]|100) ICON="􀛨"
                    COLOR=$YELLOW
        ;;
        [6-8][0-9]) ICON="􀺸"
                    COLOR=$YELLOW
        ;;
        [3-5][0-9]) ICON="􀺶"
                    COLOR=$ORANGE
        ;;
        [1-2][0-9]) ICON="􀛩"
                    COLOR=$RED
        ;;
        *)          ICON="􀛩"
                    COLOR=$RED
    esac
fi

sketchybar --set $NAME icon="$ICON" label="${PERCENTAGE}%" icon.color=$COLOR

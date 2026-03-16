#!/usr/bin/env bash

killall aerospace_plugin 2>/dev/null
aerospace_plugin &
sleep 0.2

sketchybar --add event aerospace_workspace_change

WS_LIST=$(aerospace list-workspaces --all)
ORDERED_WS="m w "
NUMERIC_WS=$(echo "$WS_LIST" | grep -v -E '^(m|w)$' | sort -n | tr '\n' ' ')
ORDERED_WS+="$NUMERIC_WS"

for sid in $ORDERED_WS; do
    sketchybar --add item "space.$sid" left                                    \
               --set "space.$sid" label="$sid"                                 \
                                  icon.font="sketchybar-app-font:Regular:16.0"

    if [[ ! "$sid" =~ ^[1-9]$ ]]; then
        sketchybar --set "space.$sid" label.drawing="off"
    fi
done

sketchybar --add item aerospace_listener left                                                      \
           --set aerospace_listener drawing="off"                                                  \
                                    updates="on"                                                   \
                                    mach_helper="aerospace_plugin_mach"                            \
           --subscribe aerospace_listener aerospace_workspace_change aerospace_custom_app_switched

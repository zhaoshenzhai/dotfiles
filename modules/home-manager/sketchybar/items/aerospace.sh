#!/usr/bin/env bash

sketchybar --add event aerospace_workspace_change

# WS_LIST=$(aerospace list-workspaces --all)
# ORDERED_WS="m w "
# NUMERIC_WS=$(echo "$WS_LIST" | grep -v -E '^(m|w)$' | sort -n | tr '\n' ' ')
# ORDERED_WS+="$NUMERIC_WS"
# for sid in $ORDERED_WS; do
for sid in $(aerospace list-workspaces --all); do
    sketchybar --add item "space.$sid" left                                    \
               --set "space.$sid" label="$sid"                                 \
                                  icon.font="sketchybar-app-font:Regular:16.0"

    if [[ ! "$sid" =~ ^[1-9]$ ]]; then
        sketchybar --set "space.$sid" label.drawing="off"
    fi
done

sketchybar --add item aerospace_listener left                                              \
           --set aerospace_listener drawing="off"                                          \
                                    updates="on"                                           \
                                    script="$HOME/.config/sketchybar/plugins/aerospace.sh" \
           --subscribe aerospace_listener aerospace_workspace_change front_app_switched

#!/usr/bin/env bash

sketchybar --add event aerospace_workspace_change
for sid in $(aerospace list-workspaces --all); do
    sketchybar --add item "space.$sid" left                                    \
               --set "space.$sid" label="$sid"                                 \
                                  background.padding_left=0                    \
                                  background.padding_right=0                   \
                                  icon.font="sketchybar-app-font:Regular:16.0"

    if [[ ! "$sid" =~ ^[0-9]$ ]]; then
        sketchybar --set "space.$sid" label.drawing="off"
    fi
done

sketchybar --add item aerospace_listener left                                              \
           --set aerospace_listener drawing="off"                                          \
                                    updates="on"                                           \
                                    script="$HOME/.config/sketchybar/plugins/aerospace.sh" \
           --subscribe aerospace_listener aerospace_workspace_change front_app_switched

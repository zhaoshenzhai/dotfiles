#!/usr/bin/env bash

sketchybar --add event aerospace_workspace_change
for sid in $(aerospace list-workspaces --all); do
    sketchybar --add item "space.$sid" left                                 \
        --subscribe "space.$sid" aerospace_workspace_change                 \
        --set "space.$sid"                                                  \
        icon="$sid"                                                         \
                              icon.padding_left=10                          \
                              icon.padding_right=10                         \
                              label.padding_right=33                        \
                              background.color=$BAR_COLOR                   \
                              background.border_width=1                     \
                              background.border_color=0xff444444            \
                              background.corner_radius=9                    \
                              background.padding_right=5                    \
                              background.padding_left=5                     \
                              background.drawing=off                        \
                              label.font="sketchybar-app-font:Regular:16.0" \
                              label.background.height=30                    \
                              label.background.drawing=on                   \
                              label.background.color=0xff494d64             \
                              label.background.corner_radius=9              \
                              label.drawing=off                             \
        click_script="aerospace workspace $sid"                             \
        script="$CONFIG_DIR/plugins/aerospace.sh $sid"
done

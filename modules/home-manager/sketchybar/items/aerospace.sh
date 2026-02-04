#!/usr/bin/env bash

sketchybar --add event aerospace_workspace_change
for sid in $(aerospace list-workspaces --all); do
    sketchybar --add item "space.$sid" left                            \
              --set "space.$sid" label="$sid"                          \
                                 label.padding_left=10                 \
                                 label.padding_right=10                \
                                 icon.padding_left=0                   \
                                 icon.padding_right=0                  \
                                 background.color=$BAR_COLOR           \
                                 background.border_width=1             \
                                 background.border_color=$BORDER_COLOR \
                                 background.corner_radius=9            \
                                 background.padding_right=2            \
                                 background.padding_left=2             \
               click_script="aerospace workspace $sid"                 \
               script="$CONFIG_DIR/plugins/aerospace.sh $sid"
done

sketchybar --add item aerospace_listener left                                              \
           --set aerospace_listener drawing=off                                            \
                                    updates=on                                             \
                                    script="$HOME/.config/sketchybar/plugins/aerospace.sh" \
           --subscribe aerospace_listener aerospace_workspace_change

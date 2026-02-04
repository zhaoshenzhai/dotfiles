#!/usr/bin/env bash

sketchybar --add event aerospace_workspace_change
for sid in $(aerospace list-workspaces --all); do
    sketchybar --add item "space.$sid" left                            \
               --subscribe "space.$sid" aerospace_workspace_change     \
                                        front_app_switched             \
               --set "space.$sid" label="$sid"                         \
                                  label.drawing=off                    \
                                  background.drawing=off               \
                                  # label.padding_right=33               \
                                  # icon.padding_left=10                 \
                                  # icon.padding_right=10                \
                                  # background.color=$BAR_COLOR          \
                                  # background.border_width=1            \
                                  # background.border_color=0xff444444   \
                                  # background.corner_radius=9           \
                                  # background.padding_right=5           \
                                  # background.padding_left=5            \
               click_script="aerospace workspace $sid"                 \
               script="$CONFIG_DIR/plugins/aerospace.sh $sid"
done

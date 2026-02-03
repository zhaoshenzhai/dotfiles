#!/usr/bin/env sh

sketchybar --add item     calendar right                    \
           --set calendar icon=$CALENDAR                    \
                          icon.color=$BLACK                 \
                          icon.font="$ICON_FONT:Black:12.0" \
                          icon.padding_left=5               \
                          icon.padding_right=5              \
                          icon.drawing=on                   \
                          label.color=$BLACK                \
                          label.padding_left=5              \
                          label.padding_right=5             \
                          background.color=0xffb8c0e0       \
                          background.height=26              \
                          background.corner_radius=11

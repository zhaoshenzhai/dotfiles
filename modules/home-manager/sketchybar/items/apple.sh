#!/usr/bin/env bash

sketchybar --add item apple left                      \
           --set apple  icon=􀣺                        \
                        icon.font.size=17             \
                        icon.y_offset=3               \
                        icon.padding_left=10          \
                        icon.padding_right=10         \
                        label.padding_left=0          \
                        label.padding_right=0         \
                        background.color=$TRANSPARENT \
                        background.border_width=0     \
                        background.padding_right=0    \
                        background.padding_left=0

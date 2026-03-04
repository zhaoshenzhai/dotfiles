#!/usr/bin/env bash

source "$HOME/.config/sketchybar/colors.sh"

killall cpu_plugin 2>/dev/null
cpu_plugin &

sketchybar --add graph cpu right 50               \
           --set cpu   y_offset=2                 \
                       graph.color=$WHITE         \
                       graph.fill_color=$WHITE_   \
                       graph.line_width=1         \
                       icon.padding_left=5        \
                       icon.padding_right=0       \
                       label.padding_left=0       \
                       label.padding_right=7      \
                       background.y_offset=-2     \
                       background.padding_left=1  \
                       background.padding_right=1

sketchybar --add item cpu.label right                      \
           --set cpu.label icon=􀫥                          \
                           icon.shadow.drawing=on          \
                           icon.shadow.color=$SHADOW_COLOR \
                           icon.shadow.angle=90            \
                           icon.shadow.distance=2          \
                           blur_radius=10                  \
                           padding_right=-45               \
                           background.drawing=off

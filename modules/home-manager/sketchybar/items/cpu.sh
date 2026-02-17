#!/usr/bin/env bash

source "$HOME/.config/sketchybar/colors.sh"

sketchybar --add graph cpu right 50                \
           --set cpu   update_freq=1               \
                       graph.color=$WHITE          \
                       graph.fill_color=0x55abb2bf \
                       graph.line_width=1          \
                       icon.pading_left=0          \
                       icon.pading_right=0         \
                       label.pading_left=0         \
                       label.pading_right=0        \
                       background.padding_left=0   \
                       background.padding_right=0  \
                       script="$PLUGIN_DIR/cpu.sh"

sketchybar --add item cpu.label right             \
           --set cpu.label icon=􀫥                 \
                           width=0                \
                           padding_right=-60      \
                           background.drawing=off

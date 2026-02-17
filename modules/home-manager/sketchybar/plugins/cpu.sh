#!/usr/bin/env bash

source "$HOME/.config/sketchybar/colors.sh"
CORE_COUNT=$(sysctl -n machdep.cpu.thread_count)

update_cpu() {
    CPU=$(ps -A -o %cpu | awk -v cores="$CORE_COUNT" '{s+=$1} END {printf "%.3f", s/cores/100}')

    if [ "$(echo "$CPU" | awk '{print ($1 > 0.4 ? 1 : 0)}')" -eq 1 ]; then
        sketchybar --set cpu graph.color=$RED graph.fill_color=$RED_
        sketchybar --set cpu.label icon.color=$RED
    elif [ "$(echo "$CPU" | awk '{print ($1 > 0.2 ? 1 : 0)}')" -eq 1 ]; then
        sketchybar --set cpu graph.color=$ORANGE graph.fill_color=$ORANGE_
        sketchybar --set cpu.label icon.color=$ORANGE
    else
        sketchybar --set cpu graph.color=$WHITE graph.fill_color=$WHITE_
        sketchybar --set cpu.label icon.color=$WHITE
    fi

    sketchybar --push cpu "$CPU"
}

update_cpu
sleep 0.5
update_cpu

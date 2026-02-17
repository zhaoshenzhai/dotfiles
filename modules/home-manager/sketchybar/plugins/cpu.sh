#!/usr/bin/env bash

CORE_COUNT=$(sysctl -n machdep.cpu.thread_count)

calculate_cpu() {
    ps -A -o %cpu | awk -v cores="$CORE_COUNT" '{s+=$1} END {printf "%.3f", s/cores/100}'
}

sketchybar --push cpu "$(calculate_cpu)"
sleep 0.5
sketchybar --push cpu "$(calculate_cpu)"

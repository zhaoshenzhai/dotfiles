#!/usr/bin/env bash

CORE_COUNT=$(sysctl -n machdep.cpu.thread_count)
CPU_PERCENT=$(ps -A -o %cpu | awk -v cores="$CORE_COUNT" '{s+=$1} END {printf "%.0f", s/cores}')

sketchybar --animate tanh 8 --set "$NAME" label="$CPU_PERCENT%"

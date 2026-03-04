#!/usr/bin/env bash

killall volume_plugin 2>/dev/null
volume_plugin &
sleep 0.2

sketchybar --add item volume right                       \
           --set volume mach_helper="volume_plugin_mach" \
           --subscribe volume volume_change

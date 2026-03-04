#!/usr/bin/env bash

killall volume_plugin 2>/dev/null
volume_plugin &

sketchybar --add item volume right                       \
           --set volume mach_helper="volume_plugin_mach" \
           --subscribe volume volume_change

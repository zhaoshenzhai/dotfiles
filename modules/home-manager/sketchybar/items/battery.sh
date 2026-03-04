#!/usr/bin/env bash

killall battery_plugin 2>/dev/null
battery_plugin battery &
sleep 0.2

sketchybar --add item battery right                            \
           --set battery mach_helper="battery_plugin_mach"     \
           --subscribe battery system_woke power_source_change

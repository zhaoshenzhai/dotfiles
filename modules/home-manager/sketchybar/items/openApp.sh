#!/usr/bin/env bash

killall openApp_plugin 2>/dev/null
openApp_plugin &
sleep 0.2

sketchybar --add event aerospace_custom_app_switched
sketchybar --add item openApp left                         \
           --set openApp mach_helper="openApp_plugin_mach" \
           --subscribe openApp aerospace_custom_app_switched front_app_switched

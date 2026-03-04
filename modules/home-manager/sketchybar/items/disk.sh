#!/usr/bin/env bash

killall disk_plugin 2>/dev/null
sketchybar --add item disk right --set disk icon=􀤂
disk_plugin disk &

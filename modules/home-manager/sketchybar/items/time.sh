#!/usr/bin/env bash

killall time_plugin 2>/dev/null
time_plugin calendar &
sketchybar --add item calendar right --set calendar icon=􀉉

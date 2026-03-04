#!/usr/bin/env bash

killall time_plugin 2>/dev/null

sketchybar --add item calendar right --set calendar icon=􀉉
time_plugin calendar &

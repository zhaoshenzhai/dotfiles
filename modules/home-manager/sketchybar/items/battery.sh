#!/usr/bin/env bash

sketchybar --add item battery right \
           --set battery update_freq=30 \
                         script="battery_plugin" \
           --subscribe battery system_woke power_source_change

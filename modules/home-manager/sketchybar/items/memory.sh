#!/usr/bin/env bash

sketchybar --add item memory right                      \
           --set memory  icon=􀫦                         \
                         update_freq=10                 \
                         script="$PLUGIN_DIR/memory.sh"

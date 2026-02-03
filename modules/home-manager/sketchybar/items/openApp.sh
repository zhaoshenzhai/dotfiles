#!/bin/bash

sketchybar --add item openApp left                                         \
           --set openApp      icon.font="sketchybar-app-font:Regular:16.0" \
                              script="$PLUGIN_DIR/openApp.sh"              \
           --subscribe openApp front_app_switched

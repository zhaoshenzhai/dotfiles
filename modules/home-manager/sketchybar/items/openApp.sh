#!/usr/bin/env bash

sketchybar --add item openApp left                       \
           --set openApp script="$PLUGIN_DIR/openApp.sh" \
           --subscribe openApp front_app_switched

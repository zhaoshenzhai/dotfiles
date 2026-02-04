#!/bin/bash

sketchybar --add item openApp right                      \
           --set openApp script="$PLUGIN_DIR/openApp.sh" \
           --subscribe openApp front_app_switched

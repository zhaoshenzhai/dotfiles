#!/usr/bin/env sh

sketchybar --add item cpu right                         \
           --set cpu  icon=􀧓                            \
                      update_freq=2                     \
                      script="$PLUGIN_DIR/cpu.sh"

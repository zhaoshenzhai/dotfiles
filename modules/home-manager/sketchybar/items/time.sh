#!/usr/bin/env bash

sketchybar --add item     calendar right                    \
           --set calendar icon=􀉉                            \
                          update_freq=1                     \
                          script="$PLUGIN_DIR/time.sh"

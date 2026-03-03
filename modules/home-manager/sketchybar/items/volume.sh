#!/usr/bin/env bash

sketchybar --add item volume right             \
           --set volume script="volume_plugin" \
           --subscribe volume volume_change

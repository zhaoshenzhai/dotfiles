#!/usr/bin/env bash
sketchybar --set "$NAME" label="$(df -H / | awk 'NR==2 {print $5}')"

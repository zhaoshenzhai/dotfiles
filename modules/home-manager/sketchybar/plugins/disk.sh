#!/usr/bin/env bash
sketchybar --set "$NAME" label="$(df -k / | awk 'NR==2 {print int(($2-$4)/$2*100) "%"}')"

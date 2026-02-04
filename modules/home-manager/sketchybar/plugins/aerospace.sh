#!/bin/bash

source "$HOME/.config/sketchybar/colors.sh"

# If we didn't get the focused workspace from the event, ask Aerospace for it
if [ -z "$FOCUSED_WORKSPACE" ]; then
    FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)
fi

# Ask Aerospace if this workspace ($1) has any windows
# We check if the output is non-empty
HAS_WINDOWS=$(aerospace list-windows --workspace "$1")

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    # Case 1: It's the focused workspace. ALWAYS show it.
    sketchybar --set $NAME drawing=on label.drawing=on background.drawing=on label.color=$WHITE icon.color=$WHITE
elif [ -n "$HAS_WINDOWS" ]; then
    # Case 2: It's NOT focused, but it HAS windows. Show it (but no background highlight).
    sketchybar --set $NAME drawing=on label.drawing=on background.drawing=off label.color=$GRAY icon.color=$GRAY
else
    # Case 3: It's NOT focused and EMPTY. Hide it.
    sketchybar --set $NAME drawing=off
fi

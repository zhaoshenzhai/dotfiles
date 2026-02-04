#!/bin/bash

source "$HOME/.config/sketchybar/colors.sh"

# 1. Get the current state ONCE
if [ -z "$FOCUSED_WORKSPACE" ]; then
    FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)
fi

# Get a list of all workspaces that have windows (non-empty)
# We store this in a string for easy grep checking
OCCUPIED_WORKSPACES=$(aerospace list-workspaces --monitor all --empty no)

# 2. Prepare the Sketchybar command
# We will build a long argument string to update everything in ONE call
ARGS=()

for sid in $(aerospace list-workspaces --all); do
    if [ "$sid" = "$FOCUSED_WORKSPACE" ]; then
        # Focused: White text, Border ON
        ARGS+=(--set "space.$sid" drawing=on label.drawing=on background.drawing=on label.color=$WHITE icon.color=$WHITE)
    elif echo "$OCCUPIED_WORKSPACES" | grep -q "$sid"; then
        # Occupied: Gray text, Border OFF
        ARGS+=(--set "space.$sid" drawing=on label.drawing=on background.drawing=off label.color=$GRAY icon.color=$GRAY)
    else
        # Empty: Hidden
        ARGS+=(--set "space.$sid" drawing=off)
    fi
done

# 3. Execute the batch update
sketchybar "${ARGS[@]}"

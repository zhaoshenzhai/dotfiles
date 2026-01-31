#!/bin/bash

# Reminders
cd /home/zhao/Dropbox/Others/Reminders
notes=$(find . -maxdepth 1 -type f | grep ".md")
while IFS= read -r note; do
    kitty --class reminders -e nvim "$note" &
done <<< "$notes"

# Applications
dropbox &
nitrogen --restore &
qutebrowser-profile --load 'Z' &
# qutebrowser-profile --load 'P' &
# spotify &

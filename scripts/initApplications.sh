#!/bin/bash

# Reminders
cd /home/zhao/Dropbox/Others/Reminders
notes=$(find . -maxdepth 1 -type f | grep ".md")
while IFS= read -r note; do
    kitty --class reminders,reminders -e nvim "$note" &
done <<< "$notes"

# Applications
dropbox &
nitrogen --restore &
$DOTFILES_DIR/scripts/openQute.sh -Z &
$DOTFILES_DIR/scripts/openQute.sh -P &
$DOTFILES_DIR/scripts/openQute.sh -M &
spotify &

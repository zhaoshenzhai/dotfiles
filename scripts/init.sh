#!/bin/bash
xset r rate 150 &                # Set keyboard repeat rate
xset b off &                     # Remove beep
xsetroot -cursor_name left_ptr   # Cursor

# Start background applications
dropbox &
nitrogen --restore &

# Open reminders
cd /home/zhao/Dropbox/Others/Reminders
notes=$(find . -maxdepth 1 -type f | grep ".md")
while IFS= read -r note; do
    kitty --class reminders,reminders -e nvim "$note" &
done <<< "$notes"

# Start applications
$DOTFILES_DIR/scripts/openQute.sh -Z &
$DOTFILES_DIR/scripts/openQute.sh -P &
spotify &
discord &

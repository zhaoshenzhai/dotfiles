#!/bin/bash
xset r rate 200 &                # Set keyboard repeat rate
xset b off &                     # Remove beep
xsetroot -cursor_name left_ptr   # Cursor

# Start background applications
dropbox &
nitrogen --restore &

# Open reminders
cd /home/zhao/Dropbox/Others/Reminders
notes=$(find . -maxdepth 1 -type f | grep ".md")
while IFS= read -r note; do
    alacritty --class reminders,reminders -e nvim "$note" &
done <<< "$notes"

# Start applications
obsidian &
LD_PRELOAD=/usr/local/lib/spotify-adblock.so spotify &
$DOTFILES_DIR/scripts/openQute.sh -Z &
$DOTFILES_DIR/scripts/openQute.sh -P &

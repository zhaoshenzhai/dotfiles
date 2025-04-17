#!/bin/bash
xset r rate 150 &
xset b off &
xsetroot -cursor_name left_ptr
xinput --set-prop 11 332 1
xinput --set-prop 11 359 1

# Open reminders
cd /home/zhao/Dropbox/Others/Reminders
notes=$(find . -maxdepth 1 -type f | grep ".md")
while IFS= read -r note; do
    kitty --class reminders,reminders -e nvim "$note" &
done <<< "$notes"

# Start applications
dropbox &
nitrogen --restore &
$DOTFILES_DIR/scripts/openQute.sh -Z &
$DOTFILES_DIR/scripts/openQute.sh -P &
spotify &

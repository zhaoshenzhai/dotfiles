#!/bin/bash
xset r rate 300 &                # Set keyboard repeat rate
xset b off &                     # Remove beep
xsetroot -cursor_name left_ptr   # Cursor

# Start background applications
dropbox &
nitrogen --restore &

# Open reminders
alacritty --class reminders,reminders -e nvim ~/Dropbox/Others/Reminders/MathWiki.md &
alacritty --class reminders,reminders -e nvim ~/Dropbox/Others/Reminders/Dates.md &
alacritty --class reminders,reminders -e nvim ~/Dropbox/Others/Reminders/Items.md &
zathura '~/Dropbox/University/Courses/22F/MATH133/Syllabus/Fall 2020.pdf' &

# Start main applications
sleep 10
obsidian &
sleep 10
spotify &

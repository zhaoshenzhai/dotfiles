#!/bin/bash
xset r rate 250 &                                   # Set keyboard repeat rate
xset b off &                                        # Remove beep
nmcli dev wifi con Z &                              # Wifi

# Start background applications
dropbox &
nitrogen --restore &

# Open reminders
alacritty --class reminders,reminders -e nvim ~/Dropbox/Reminders/MathWiki.md &
alacritty --class reminders,reminders -e nvim ~/Dropbox/Reminders/Dates.md &
zathura '~/Dropbox/University/Courses/22F/MATH133/Fall 2020.pdf' &

# Start main applications
google-chrome-stable --profile-directory=Default --force-dark-mode &
obsidian &
spotify &

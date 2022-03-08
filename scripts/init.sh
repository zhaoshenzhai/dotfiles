#!/bin/bash
xset r rate 250 &                                   # Set keyboard repeat rate
xset b off &                                        # Remove beep
nmcli dev wifi con Z &                              # Wifi

# Start background applications
dropbox &
nitrogen --restore &

# Open reminders
alacritty --class reminders,reminders -e nvim ~/Dropbox/Reminders/MathWiki.md &

# Start main applications
google-chrome-stable --profile-directory=Default --force-dark-mode &
obsidian &
spotify &

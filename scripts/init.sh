#!/bin/bash
xset r rate 250 &                                   # Set keyboard repeat rate
xset b off &                                        # Remove beep
nmcli dev wifi con Z &                              # Wifi

# Start background applications
dropbox &
nitrogen --restore &

# Open reminders
alacritty --class reminders,reminders -e nvim ~/Reminders/self_study.md &

# Start main applications
google-chrome-stable --profile-directory=Default &
obsidian &
spotify &

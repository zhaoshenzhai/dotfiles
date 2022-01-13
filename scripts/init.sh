#!/bin/bash
xset r rate 250 &                                   # Set keyboard repeat rate
xset b off &                                        # Remove beep

# Start applications
dropbox &
nitrogen --restore &

#Open reminders
alacritty --class reminders,reminders -e nvim ~/Reminders/self_study.md &

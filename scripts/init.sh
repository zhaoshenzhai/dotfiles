#!/bin/bash
xset r rate 250 &                                   # Set keyboard repeat rate
xset b off &                                        # Remove beep

# Start applications
dropbox &
nitrogen --restore &
pulseaudio -k
pulseaudio --start

#Open reminders
alacritty --class reminders,reminders -e nvim ~/.config/notes/Topology &

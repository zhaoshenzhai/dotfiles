#!/bin/bash
xset r rate 250 &                                   # Set keyboard repeat rate
xset b off &                                        # Remove beep
nmcli dev wifi con Z-5GHz &                         # Wifi

# Start applications
dropbox &
nitrogen --restore &

#Open reminders
alacritty --class reminders,reminders -e nvim ~/Reminders/self_study.md &

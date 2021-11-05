#!/bin/bash
xset r rate 250 &                                   # Set keyboard repeat rate

# Start applications
picom --experimental-backends &
dropbox &
nitrogen --restore &
wal -i "/home/zhao/.wallpapers/lake.jpg" & 

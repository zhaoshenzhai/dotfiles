#!/bin/bash
xset r rate 300 &                                   # Set keyboard repeat rate
xset b off &                                        # Remove beep
xsetroot -cursor_name left_ptr                      # Cursor
nmcli dev wifi con Z &                              # Wifi
bluetoothctl power on &                             # Bluetooth

# Start background applications
dropbox &
nitrogen --restore &

# Open reminders
alacritty --class reminders,reminders -e nvim ~/Dropbox/Others/Reminders/MathWiki.md &
alacritty --class reminders,reminders -e nvim ~/Dropbox/Others/Reminders/Dates.md &
alacritty --class reminders,reminders -e nvim ~/Dropbox/Others/Reminders/Items.md &
zathura '~/Dropbox/University/Courses/22F/MATH133/Syllabus/Fall 2020.pdf' &

# Start main applications
obsidian &
sleep 20
spotify &
#google-chrome-stable --profile-directory=Default --force-dark-mode https://www.youtube.com https://mail.google.com/mail/u/0/#inbox https://outlook.office.com/mail/inbox https://github.com/zhaoshenzhai https://math.stackexchange.com &

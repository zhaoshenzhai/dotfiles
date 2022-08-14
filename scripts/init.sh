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

# Start applications if on chips
if [[ `cat /etc/hostname` == 'chips' ]]; then
    obsidian &
    spotify &
    qutebrowser-profile --new 'Z' https://www.youtube.com https://www.github.com/zhaoshenzhai https://mail.google.com/mail/u/0 https://outlook.office.com/mail &
fi

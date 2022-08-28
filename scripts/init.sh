#!/bin/bash
xset r rate 300 &                # Set keyboard repeat rate
xset b off &                     # Remove beep
xsetroot -cursor_name left_ptr   # Cursor

# Start background applications
dropbox &
nitrogen --restore &

# Open reminders
notes=$(find "/home/zhao/Dropbox/Others/Reminders" -maxdepth 1 -type f | grep ".md")
while IFS= read -r note; do
    alacritty --class reminders,reminders -e nvim "$note" &
done <<< "$notes"

# Start applications if on chips
if [[ `cat /etc/hostname` == 'chips' ]]; then
    obsidian &
    LD_PRELOAD=/usr/local/lib/spotify-adblock.so spotify &
    qutebrowser-profile --new 'Z' https://www.youtube.com https://www.github.com/zhaoshenzhai https://mail.google.com/mail/u/0 https://outlook.office.com/mail &
fi

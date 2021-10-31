#!/bin/bash

export PATH="$PATH:$HOME/bin"
export PATH="/home/zhao/.local/bin:$PATH"
export PATH="/home/zhao/.config/scripts:$PATH"
export PATH=/usr/zhao/sbin:/usr/zhao/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin;

/usr/bin/variety -n &

sleep 2s

wallpaper_path=$(<~/.config/variety/wallpaper/wallpaper.jpg.txt)

/home/zhao/.local/bin/wal -i $wallpaper_path --backend wal

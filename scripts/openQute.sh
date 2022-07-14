#!/bin/bash

while [ ! -z "$1" ]; do
    case "$1" in
        -Z)
            shift
            echo -e "\nconfig.bind('<Meta+m>', 'hint links spawn -d mpv --ytdl-raw-options=\'sub-lang="en",write-auto-sub=,cookies=~/.config/cookies_Z.txt,mark-watched=\' {hint-url} &')" >> ~/.config/qutebrowser/config.py
            `qutebrowser-profile --new 'Z'`
            sleep 5
            sed -i '$d' ~/.config/qutebrowser/config.py
            sed -i '$d' ~/.config/qutebrowser/config.py
            ;;
        -P)
            shift
            echo -e "\nconfig.bind('<Meta+m>', 'hint links spawn -d mpv --ytdl-raw-options=\'sub-lang="en",write-auto-sub=,cookies=~/.config/cookies_P.txt,mark-watched=\' {hint-url} &')" >> ~/.config/qutebrowser/config.py
            `qutebrowser-profile --new 'P'`
            sleep 5
            sed -i '$d' ~/.config/qutebrowser/config.py
            sed -i '$d' ~/.config/qutebrowser/config.py
            ;;
    esac
shift
done

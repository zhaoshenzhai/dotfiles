#!/bin/bash

while [ ! -z "$1" ]; do
    case "$1" in
        -Z)
            shift
            sed -i 's/cookies_P/cookies_Z/g' $DOTFILES_DIR/config/qutebrowser/config.py
            $(qutebrowser-profile --load 'Z' --new https://calendar.google.com/calendar https://mail.google.com/mail/u/0 https://outlook.office.com/mail)
            ;;
        -P)
            shift
            sed -i 's/cookies_Z/cookies_P/g' $DOTFILES_DIR/config/qutebrowser/config.py
            $(qutebrowser-profile --load 'P' --new https://web.whatsapp.com https://www.instagram.com/direct/inbox https://www.facebook.com/messages)
            sleep 2
            sed -i 's/cookies_P/cookies_Z/g' $DOTFILES_DIR/config/qutebrowser/config.py
            ;;
        -M)
            shift
            cd $MATHWIKI_DIR
            rm -rf Site/.local
            hugo serve -d Site/.local &
            mkdir "Site/.local/qute"
            $(qutebrowser "http://localhost:1313/mathwiki/" -s "window.title_format" "MathWiki") &
            ;;
    esac
shift
done

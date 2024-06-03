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
            hugo serve -d Site/.local --disableLiveReload &
            mkdir "Site/.local/qute"
            $(qutebrowser "http://localhost:1313/mathwiki/"\
                :'set -u localhost:1313 input.mode_override passthrough'\
                :'set statusbar.show never'\
                :'mode-enter passthrough'\
                :'bind --mode=passthrough <Meta+w> tab-close'\
                :'bind --mode=passthrough <Meta+h> back'\
                :'bind --mode=passthrough <Meta+j> tab-prev'\
                :'bind --mode=passthrough <Meta+k> tab-next'\
                :'bind --mode=passthrough <Meta+l> forward'\
                :'bind --mode=passthrough <Meta+r> reload'\
                :'bind --mode=passthrough j scroll down'\
                :'bind --mode=passthrough k scroll up'\
                -s "window.title_format" "MathWiki") &
            ;;
    esac
shift
done

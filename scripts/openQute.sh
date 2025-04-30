#!/bin/bash

while [ ! -z "$1" ]; do
    case "$1" in
        -Z)
            shift
            $(qutebrowser-profile --load 'Z' --new https://calendar.google.com/calendar https://mail.google.com/mail/u/0 https://outlook.office.com/mail)
            ;;
        -P)
            shift
            $(qutebrowser-profile --load 'P' --new https://web.whatsapp.com https://www.instagram.com/direct/inbox https://www.facebook.com/messages)
            ;;
        -M)
            shift
            killall hugo
            cd $MATHWIKI_DIR
            rm -rf Site/.local
            hugo serve -d Site/.local --disableLiveReload &
            $(qutebrowser "http://localhost:1313/mathwiki/"\
                :'set -u localhost:1313 input.mode_override passthrough'\
                :'set statusbar.show never'\
                :'mode-enter passthrough'\
                :'bind --mode=passthrough <Meta+w> tab-close'\
                :'bind --mode=passthrough <Meta+h> back'\
                :'bind --mode=passthrough <Meta+l> forward'\
                :'bind --mode=passthrough <Meta+j> tab-prev'\
                :'bind --mode=passthrough <Meta+k> tab-next'\
                :'bind --mode=passthrough <Meta+r> reload'\
                -s "window.title_format" "MathWiki") &
            ;;
    esac
shift
done

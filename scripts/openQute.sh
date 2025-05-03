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
            hugo serve -d Site/.local &
            $(qutebrowser "http://localhost:1313/mathwiki/"\
                :'set -u localhost:1313 input.mode_override passthrough'\
                :'set statusbar.show never'\
                :'mode-enter passthrough'\
                :'bind --mode=passthrough <Ctrl+g> scroll top'\
                :'bind --mode=passthrough <Ctrl+Shift+g> scroll bottom'\
                :'bind --mode=passthrough <Ctrl+o> undo'\
                :'bind --mode=passthrough <Ctrl+f> hint'\
                :'bind --mode=passthrough <Ctrl+u> cmd-repeat 20 scroll up'\
                :'bind --mode=passthrough <Ctrl+d> cmd-repeat 20 scroll down'\
                :'bind --mode=passthrough <Ctrl+w> tab-close'\
                :'bind --mode=passthrough <Ctrl+h> back'\
                :'bind --mode=passthrough <Ctrl+l> forward'\
                :'bind --mode=passthrough <Ctrl+j> tab-prev'\
                :'bind --mode=passthrough <Ctrl+k> tab-next'\
                :'bind --mode=passthrough <Ctrl+r> reload'\
                -s "window.title_format" "MathWiki") &
            ;;
    esac
shift
done

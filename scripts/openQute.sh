#!/bin/bash

while [ ! -z "$1" ]; do
    case "$1" in
        -Z)
            shift
            $(qutebrowser-profile --load 'Z' --new https://calendar.google.comhttps://mail.google.com https://outlook.office.com)
            ;;
        -P)
            shift
            $(qutebrowser-profile --load 'P' --new https://web.whatsapp.com https://www.instagram.com/direct/inbox https://discord.com/channels/@me)
            ;;
        -M)
            shift
            killall hugo > /dev/null 2>&1
            cd $MATHWIKI_DIR
            rm -rf Site/.local
            hugo serve -d Site/.local --disableLiveReload > /dev/null 2>&1 &

            name=
            if [[ ! -z "$1" ]]; then
                name=$1
            fi

            $(qutebrowser "http://localhost:1313/mathwiki/$name"\
                :'set -u localhost:1313 input.mode_override passthrough'\
                :'set statusbar.show never'\
                :'mode-enter passthrough'\
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
                -s "window.title_format" "MathWiki") > /dev/null 2>&1
            ;;
    esac
shift
done

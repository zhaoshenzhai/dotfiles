#!/bin/bash

while [ ! -z "$1" ]; do
    case "$1" in
        -Z)
            shift
            $(qutebrowser-profile --load 'Z' --new https://calendar.google.com https://mail.google.com https://outlook.office.com)
            ;;
        -P)
            shift
            $(qutebrowser-profile --load 'P' --new https://web.whatsapp.com https://www.instagram.com/direct/inbox https://discord.com/channels/@me https://www.facebook.com/messages)
            ;;
    esac
shift
done

#!/bin/bash

while [ ! -z "$1" ]; do
    case "$1" in
        -Z)
            shift
            $(qutebrowser-profile --load 'Z' --new https://mail.google.com https://outlook.office.com)
            ;;
        -P)
            shift
            $(qutebrowser-profile --load 'P' --new https://youtube.com)
            ;;
    esac
shift
done

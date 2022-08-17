#!/bin/bash

while [ ! -z "$1" ]; do
    case "$1" in
        -Z)
            shift
            sed -i 's/cookies_P/cookies_Z/g' $DOTFILES_DIR/config/qutebrowser/config.py
            `qutebrowser-profile --new 'Z'`
            ;;
        -P)
            shift
            sed -i 's/cookies_Z/cookies_P/g' $DOTFILES_DIR/config/qutebrowser/config.py
            `qutebrowser-profile --new 'P'`
            sleep 2
            sed -i 's/cookies_P/cookies_Z/g' $DOTFILES_DIR/config/qutebrowser/config.py
            ;;
    esac
shift
done

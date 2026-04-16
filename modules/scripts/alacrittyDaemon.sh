#!/usr/bin/env bash

export ALACRITTY_SOCKET="/tmp/alacritty.sock"

if [ -S "$ALACRITTY_SOCKET" ]; then
    if ! pgrep -x "alacritty" > /dev/null; then
        rm -f "$ALACRITTY_SOCKET"
    fi
fi

if alacritty msg create-window "$@" > /dev/null 2>&1; then
    exit 0
fi

rm -f "$ALACRITTY_SOCKET"
open -na Alacritty --args --daemon --socket "$ALACRITTY_SOCKET" > /dev/null 2>&1

for i in {1..10}; do
    [ -S "$ALACRITTY_SOCKET" ] && break
    sleep 0.1
done

if ! alacritty msg create-window "$@" > /dev/null 2>&1; then
    open -na Alacritty --args "$@" > /dev/null 2>&1
fi

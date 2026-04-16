#!/usr/bin/env bash

SOCKET="/tmp/alacritty.sock"

if [ -S "$SOCKET" ]; then
    if ! pgrep -x "alacritty" > /dev/null; then
        rm -f "$SOCKET"
    fi
fi

if ALACRITTY_SOCKET="$SOCKET" alacritty msg create-window "$@" > /dev/null 2>&1; then
    exit 0
fi

rm -f "$SOCKET"
nohup alacritty --daemon --socket "$SOCKET" > /dev/null 2>&1 &

for i in {1..10}; do
    [ -S "$SOCKET" ] && break
    sleep 0.1
done

if ! ALACRITTY_SOCKET="$SOCKET" alacritty msg create-window "$@" > /dev/null 2>&1; then
    nohup alacritty "$@" > /dev/null 2>&1 &
fi

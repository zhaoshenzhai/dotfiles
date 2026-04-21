#!/usr/bin/env bash

SOCKET="/tmp/alacritty.sock"
LOCKDIR="/tmp/alacritty_daemon.lock"

if [ -S "$SOCKET" ]; then
    if ! pgrep -x "alacritty" > /dev/null; then
        rm -f "$SOCKET"
        rm -rf "$LOCKDIR"
    fi
fi

if ALACRITTY_SOCKET="$SOCKET" alacritty msg create-window "$@" > /dev/null 2>&1; then
    exit 0
fi

if mkdir "$LOCKDIR" 2>/dev/null; then
    trap 'rm -rf "$LOCKDIR"' EXIT
    rm -f "$SOCKET"
    nohup alacritty --daemon --socket "$SOCKET" > /dev/null 2>&1 &

    for i in {1..20}; do
        [ -S "$SOCKET" ] && break
        sleep 0.1
    done
else
    for i in {1..30}; do
        [ -S "$SOCKET" ] && break
        sleep 0.1
    done
fi

if ! ALACRITTY_SOCKET="$SOCKET" alacritty msg create-window "$@" > /dev/null 2>&1; then
    nohup alacritty "$@" > /dev/null 2>&1 &
fi

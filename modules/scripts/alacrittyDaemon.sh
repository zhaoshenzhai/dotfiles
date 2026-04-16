#!/usr/bin/env bash

SOCKET="/tmp/alacritty.sock"
LOCKDIR="/tmp/alacritty_daemon.lock"

# 1. Clean up stale socket and orphaned locks
if [ -S "$SOCKET" ]; then
    if ! pgrep -x "alacritty" > /dev/null; then
        rm -f "$SOCKET"
        rm -rf "$LOCKDIR"
    fi
fi

# 2. Try IPC
if ALACRITTY_SOCKET="$SOCKET" alacritty msg create-window "$@" > /dev/null 2>&1; then
    exit 0
fi

# 3. Race-condition lock: Only the FIRST process gets to run the daemon
if mkdir "$LOCKDIR" 2>/dev/null; then
    # Auto-release the lock when done
    trap 'rm -rf "$LOCKDIR"' EXIT

    rm -f "$SOCKET"
    nohup alacritty --daemon --socket "$SOCKET" > /dev/null 2>&1 &

    # Wait for the new daemon to create the socket
    for i in {1..20}; do
        [ -S "$SOCKET" ] && break
        sleep 0.1
    done
else
    # 4. Lock failed: Another keypress already started the daemon. Just wait for it.
    for i in {1..30}; do
        [ -S "$SOCKET" ] && break
        sleep 0.1
    done
fi

# 5. Final fallback
if ! ALACRITTY_SOCKET="$SOCKET" alacritty msg create-window "$@" > /dev/null 2>&1; then
    nohup alacritty "$@" > /dev/null 2>&1 &
fi

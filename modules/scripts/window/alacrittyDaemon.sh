#!/usr/bin/env bash

SOCKET="/tmp/alacritty.sock"
LOCKDIR="/tmp/alacritty_daemon.lock"

# Arrays to parse and separate arguments
ENV_VARS=()
ALACRITTY_ARGS=()
CUSTOM_CMD=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --env)
            ENV_VARS+=("$2")
            shift 2
            ;;
        -e|--command)
            shift
            CUSTOM_CMD=("$@")
            break
            ;;
        *)
            ALACRITTY_ARGS+=("$1")
            shift
            ;;
    esac
done

# If --env was used, append it via Alacritty's execution flag
if [[ ${#ENV_VARS[@]} -gt 0 ]]; then
    if [[ ${#CUSTOM_CMD[@]} -gt 0 ]]; then
        ALACRITTY_ARGS+=("-e" "env" "${ENV_VARS[@]}" "${CUSTOM_CMD[@]}")
    else
        ALACRITTY_ARGS+=("-e" "env" "${ENV_VARS[@]}" "${SHELL:-/bin/zsh}")
    fi
elif [[ ${#CUSTOM_CMD[@]} -gt 0 ]]; then
    ALACRITTY_ARGS+=("-e" "${CUSTOM_CMD[@]}")
fi

if [ -S "$SOCKET" ]; then
    if ! pgrep -x "alacritty" > /dev/null; then
        rm -f "$SOCKET"
        rm -rf "$LOCKDIR"
    fi
fi

if ALACRITTY_SOCKET="$SOCKET" alacritty msg create-window "${ALACRITTY_ARGS[@]}" > /dev/null 2>&1; then
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

if ! ALACRITTY_SOCKET="$SOCKET" alacritty msg create-window "${ALACRITTY_ARGS[@]}" > /dev/null 2>&1; then
    nohup alacritty "${ALACRITTY_ARGS[@]}" > /dev/null 2>&1 &
fi

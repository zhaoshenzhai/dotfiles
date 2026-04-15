#!/usr/bin/env bash

if alacritty msg create-window "$@" >/dev/null 2>&1; then
    exit 0
fi

nohup alacritty --daemon >/dev/null 2>&1 &
sleep 0.2
alacritty msg create-window "$@" >/dev/null 2>&1 || nohup alacritty "$@" >/dev/null 2>&1 &

#!/usr/bin/env bash

sketchybar --add item openApp left                \
           --set openApp script="openApp_plugin"  \
           --subscribe openApp front_app_switched

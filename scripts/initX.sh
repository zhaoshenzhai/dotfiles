#!/bin/bash
sudo killall xremap
sudo xremap /home/zhao/.config/xremap/config.yml &
sleep 1
xset r rate 150
xset b off
xsetroot -cursor_name left_ptr
xinput set-prop 11 332 1
xinput set-prop 11 359 1

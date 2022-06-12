#!/bin/bash

rootAvail=$(df --output=avail | sed -n 4p | awk '{$1=$1};1')
rootUsed=$(df --output=used | sed -n 4p | awk '{$1=$1};1')
rootPercent=$(bc -l <<< 'scale=3; '"$rootUsed"'/('"$rootUsed"'+'"$rootAvail"')' | sed 's/.//' | sed 's/./&./2' | sed 's/^0*//')

homeAvail=$(df --output=avail | sed -n 7p | awk '{$1=$1};1')
homeUsed=$(df --output=used | sed -n 7p | awk '{$1=$1};1')
homePercent=$(bc -l <<< 'scale=3; '"$homeUsed"'/('"$homeUsed"'+'"$homeAvail"')' | sed 's/.//' | sed 's/./&./2' | sed 's/^0*//')

printf "%s %s" "<fn=1></fn>" "$rootPercent% | $homePercent%"

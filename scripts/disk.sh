#!/bin/bash

avail=$(df --output=avail | sed -n 5p | awk '{$1=$1};1')
used=$(df --output=used | sed -n 5p | awk '{$1=$1};1')
percent=$(echo "scale=3; $used/($used+$avail)" | bc | sed 's/.//' | sed 's/./&./2' | sed 's/^0*//')

printf "%s %s" "<fn=2> </fn>" "$percent%"

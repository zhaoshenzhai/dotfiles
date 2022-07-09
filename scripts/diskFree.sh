#!/bin/bash

avail=$(df --output=avail | sed -n 4p | awk '{$1=$1};1')
used=$(df --output=used | sed -n 4p | awk '{$1=$1};1')
percent=$(bc -l <<< 'scale=3; '"$used"'/('"$used"'+'"$avail"')' | sed 's/.//' | sed 's/./&./2' | sed 's/^0*//')

printf "%s %s" "<fn=1></fn>" "$percent%"

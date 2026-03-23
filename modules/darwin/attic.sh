#!/usr/bin/env bash

ATTIC_DIR="$HOME/iCloud/Projects/_attic"
TEMPLATE_FILE="$HOME/iCloud/Dotfiles/modules/darwin/LaTeXTemplate/files/attic.tex"

mkdir -p "$ATTIC_DIR"

local ID
while true; do
    ID=$(awk -v min=0 -v max=99999 'BEGIN{srand(); printf "%05d\n", int(min+rand()*(max-min+1))}')
    if [ ! -d "$ATTIC_DIR/$ID" ]; then
        break
    fi
done

mkdir -p "$ATTIC_DIR/$ID"
cd "$ATTIC_DIR/$ID"

touch keywords
cp "$TEMPLATE_FILE" "$ID.tex"

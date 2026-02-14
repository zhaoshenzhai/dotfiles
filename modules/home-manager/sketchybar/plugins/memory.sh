#!/usr/bin/env bash

TOTAL_BYTES=$(sysctl -n hw.memsize)

VM_STATS=$(vm_stat)
PAGE_SIZE=$(echo "$VM_STATS" | grep "page size of" | awk '{print $8}')

FREE=$(echo "$VM_STATS" | awk '/Pages free/ {print $3}' | sed 's/\.//')
INACTIVE=$(echo "$VM_STATS" | awk '/Pages inactive/ {print $3}' | sed 's/\.//')
SPECULATIVE=$(echo "$VM_STATS" | awk '/Pages speculative/ {print $3}' | sed 's/\.//')

AVAILABLE_PAGES=$((FREE + INACTIVE + SPECULATIVE))
AVAILABLE_BYTES=$((AVAILABLE_PAGES * PAGE_SIZE))

USED_BYTES=$((TOTAL_BYTES - AVAILABLE_BYTES))
PERCENTAGE=$((USED_BYTES * 100 / TOTAL_BYTES))

sketchybar --set "$NAME" label="$PERCENTAGE%"

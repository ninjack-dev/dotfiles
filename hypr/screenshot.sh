#!/usr/bin/env bash

# Disable fading during layer exit
hyprctl keyword animation "fadeLayersOut, 0"  
# The following logic prevents hanging. -g - reads from STDIN, and errors out if it's empty (which it is if slurp fails)
slurp -d | grim -g - - | tee $HOME/Pictures/Captures/$(date +%m-%y)/$(date +%d-%H:%M).png | $COPY_UTIL
# Re-enable fading during layer exit (no use for it yet but we'll see)
hyprctl keyword animation "fadeLayersOut, 1"

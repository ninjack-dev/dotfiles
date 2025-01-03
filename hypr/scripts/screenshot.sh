#!/usr/bin/env bash

# https://tldp.org/LDP/Bash-Beginners-Guide/html/sect_12_02.html
function sigterm_handler {
  exit 0
}
trap sigterm_handler SIGTERM

function screen_record {
  type=gif
  video_fifo="/tmp/$(date +%d-%H:%M)"
  video_file="$HOME/Pictures/Captures/$(date +%m-%y)/$(date +%d-%H:%M).$type"
  mkfifo "$video_fifo"
  
  wf-recorder --geometry "$(slurp -d)" -F fps=20 -c gif -o "$video_fifo"
  echo "Recording done"
  dd if="$video_fifo" of="$video_file"
# We don't have hints with AGS for now.
notify-send " " "Screen recorder buffer is hitting the limit (1GB). Would you like to cancel the recording, start writing, or end the recording?" --action=cancel=Cancel --action=write="Start Writing" --expire-time=2000 --wait --app-name="Screen Recorder" --icon=discord --hint=int:default_index:0 -e
}

CAPTURE_PATH="$HOME/Pictures/Captures/$(date +%m-%y)"
mkdir -p "$CAPTURE_PATH"

# Disable fading during layer exit
hyprctl keyword animation "fadeLayersOut, 0"  
# The following logic prevents hanging. `-g -` reads from STDIN, and errors out if it's empty (which it is if slurp fails)
slurp -d | grim -g - - | tee $CAPTURE_PATH/$(date +%d-%H:%M).png | $COPY_UTIL
# Re-enable fading during layer exit (no use for it yet but we'll see)
hyprctl keyword animation "fadeLayersOut, 1"

#!/usr/bin/env bash

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

# Fetch fadeLayersOut's current animation data BEFORE disabling it, so it can be restored exactly.
fade_layers_out_lua="$(hyprctl animations -j | jq -r '.[0][] | select(.name == "fadeLayersOut") | {enabled, speed: (if .speed > 0 then .speed else 1 end), bezier: (if .bezier == "" then "default" else .bezier end), style} | "enabled = \(.enabled), speed = \(.speed), bezier = \(.bezier | @json), style = \(.style | @json)"')"
if [ -z "$fade_layers_out_lua" ]; then
  fade_layers_out_lua='enabled = true, speed = 1, bezier = "default", style = ""'
fi

# Disable fading during layer exit
hyprctl eval 'hl.animation({ leaf = "fadeLayersOut", enabled = false, speed = 0 })'
# The following logic prevents hanging. `-g -` reads from STDIN, and errors out if it's empty (which it is if slurp fails)
slurp -d | grim -g - - | tee "$CAPTURE_PATH/$(date +%d-%H:%M).png" | wl-copy
# Re-enable fading during layer exit, restoring the original animation data
hyprctl eval "hl.animation({ leaf = \"fadeLayersOut\", $fade_layers_out_lua })"

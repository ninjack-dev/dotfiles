#!/bin/sh

if hyprctl clients | grep 'class: '"$1"; then
  if [ "$2" = 'pull' ]; then
hyprctl dispatch movetoworkspace e+0, 'class:'"$1"
  fi
    hyprctl dispatch focuswindow 'class:'"$1"
else 
  $1
fi

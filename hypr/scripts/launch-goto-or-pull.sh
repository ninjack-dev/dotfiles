#!/bin/sh

if hyprctl clients | grep 'class: obsidian'; then
  if [ "$1" = 'pull' ]; then
hyprctl dispatch movetoworkspace e+0, 'class:obsidian'
  fi
    hyprctl dispatch focuswindow 'class:obsidian'
else 
  obsidian
fi

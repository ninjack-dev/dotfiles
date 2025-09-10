#!/usr/bin/env bash

activewindow_address=$(hyprctl -j activewindow | jq -r '.address')

if [[ $(hyprctl getprop "address:$activewindow_address" noscreenshare) == "true" ]]; then
  action=$(notify-send --icon=hyprland --app-name='Hyprland' "The current window is currently blocked from screenshare. Are you sure you want to reveal it?" --action=Yes --action='No (default)' 2> /dev/null)
  if [[ $action == "Yes" ]]; then
    hyprctl dispatch setprop "address:$activewindow_address" noscreenshare off
  fi
else
  hyprctl dispatch setprop "address:$activewindow_address" noscreenshare on
fi

#!/usr/bin/env bash

# Usage: <program to launch> <window class> <action>
class=
program=
action=

while [[ "$#" -gt 0 ]]; do
  [[ $1 == --*=* ]] && set -- "${1%%=*}" "${1#*=}" "${@:2}"
  # Mostly unusable for now
  case $1 in
    --class*)
      class="$2"
      shift 1 2> /dev/null || {
        printf "No class provided with %s!\n" "$1" >&2
        exit 1
      }
      ;;
    --program*)
      program="$2"
      shift 1 2> /dev/null || {
        printf "No program provided with %s!\n" "$1" >&2
        exit 1
      }
      ;;
    --action*)
      action="$2"
      shift 1 2> /dev/null || {
        printf "No action provided with %s!\n" "$1" >&2
        exit 1
      }
      ;;
    *)
      if [[ -z "$program" ]]; then
        program=$1
      elif [[ -z "$class" ]]; then
        class=$1
      elif [[ -z "$action" ]]; then
        action=$1
      fi
      ;;
  esac
  shift 1 2> /dev/null
done

if hyprctl clients | grep "class: $class" > /dev/null 2>&1; then
  case "$action" in
    "goto")
      hyprctl dispatch focuswindow "class:$class"
      ;;
    "pull")
      hyprctl dispatch movetoworkspace e+0, "class:$class"
      ;;
  esac
else
  hyprctl dispatch exec "$program"
fi

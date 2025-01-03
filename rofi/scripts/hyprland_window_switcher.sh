#!/usr/bin/env bash
# https://github.com/lbonn/rofi/blob/wayland/doc/rofi-script.5.markdown

declare -r INITIAL_CALL=0
declare -r DEFAULT_SELECT=1
declare -r CUSTOM_ENTRY=2
declare -r CUSTOM_BIND_1=10

if [ "$ROFI_RETV" -eq $INITIAL_CALL ]; then
  echo -en "\0prompt\x1f\n"
  echo -en "\0use-hot-keys\x1ftrue\n"
  hyprctl clients | 
  awk '
    BEGIN { ORS = "\n" }
    /Window/ { window_id = $2 }
    /class:/ { class = substr($0, index($0,$2)) }
    /title:/ { title = substr($0, index($0,$2)) }
    /focusHistoryID:/ { 
    focusHistoryID = substr($0, index($0,$2)) 

    print window_id "\t" class "\t" title "\t" focusHistoryID
    # print window_id, class, title, focusHistoryID
    # print window_id ", " class ", \"" title "\", " focusHistoryID
    # print window_id "\n" class "\n" title "\n" focusHistoryID "\n" 
    }
    ' |
  sort -t$'\t' -k4n | { # I hope windows can't have a tab in the title
  while IFS=$'\t' read -r window_id class title focus_index; do
    if [ "$focus_index" -eq 0 ]; then
      # Don't show include the currently focused window
      continue
    fi
    # Encode the window address in the `info` category, referenced by ROFI_INFO
    echo -en "$title\0icon\x1f$class\x1finfo\x1f$window_id\n"; 
  done 
  }
  exit 0
fi

case "$ROFI_RETV" in
  $DEFAULT_SELECT)
  coproc hyprctl dispatch focuswindow address:"0x$ROFI_INFO" >/dev/null 2>&1 
  # For some reason, without coproc, the dispatcher doesn't follow through all the way; it moves the cursor but doesn't focus the window
    ;;
  $CUSTOM_BIND_1)
 coproc hyprctl dispatch movetoworkspace \
   "$(hyprctl monitors | awk '/active workspace:/ { workspace = $3} /focused: yes/ { print workspace }')",\
    address:"0x$ROFI_INFO" >/dev/null 2>&1
    ;;
esac


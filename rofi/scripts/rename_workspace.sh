declare -r INITIAL_CALL=0
declare -r DEFAULT_SELECT=1
declare -r CUSTOM_ENTRY=2
declare -r CUSTOM_BIND_1=10

echo -en "\0prompt\x1fRename Current Workspace\n"
echo -en "\0theme\x1flistview { enabled: false; }\n"
echo -en "\0theme\x1finputbar { border-radius: 6px ; }\n"

case "$ROFI_RETV" in
  $INITIAL_CALL)
    
    ;;
  $DEFAULT_SELECT)
    hyprctl dispatch renameworkspace "$(hyprctl monitors | awk '/active workspace:/ { workspace = $3} /focused: yes/ { print workspace }')" $1 &>/dev/null
    exit 0
    ;;
  $CUSTOM_ENTRY)
    hyprctl dispatch renameworkspace "$(hyprctl monitors | awk '/active workspace:/ { workspace = $3} /focused: yes/ { print workspace }')" $1 &>/dev/null
    exit 0
    ;;
esac



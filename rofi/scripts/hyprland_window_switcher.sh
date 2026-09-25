#!/usr/bin/env bash
# rofi script protocol: https://github.com/lbonn/rofi/blob/wayland/doc/rofi-script.5.markdown

declare -r INITIAL_CALL=0
declare -r DEFAULT_SELECT=1
declare -r CUSTOM_BIND_1=10

declare -a APP_DIRS

populate_app_dirs() {
  local -a xdg
  local -A seen=()
  local dir
  IFS=: read -ra xdg <<< "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
  APP_DIRS=()
  for dir in "${XDG_DATA_HOME:-$HOME/.local/share}/applications" "${xdg[@]/%//applications}"; do
    [[ -n ${seen[$dir]+x} ]] && continue
    seen[$dir]=1
    APP_DIRS+=("$dir")
  done
}

# rofi resolves the emitted \0icon\x1f value by name, but a window's class/app_id
# is not its icon name (class "codium" vs Icon=vscodium). Map class and
# StartupWMClass to the desktop entry's Icon=; scanning every entry is slow for a
# keybind, so cache per session and rebuild only when the script or an app dir
# changes.
ICON_CACHE="${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}}/rofi-window-icons.tsv"

icon_cache_stale() {
  [[ -s $ICON_CACHE ]] || return 0
  [[ -f $0 && $0 -nt $ICON_CACHE ]] && return 0
  local dir
  for dir in "${APP_DIRS[@]}"; do
    [[ -d $dir && $dir -nt $ICON_CACHE ]] && return 0
  done
  return 1
}

build_icon_cache() {
  local dir file line key value stem wm
  local -A icon_by_class icon_of_file wm_of_file
  local -a files

  for dir in "${APP_DIRS[@]}"; do
    files=("$dir"/*.desktop)
    [[ -e ${files[0]} ]] || continue
    icon_of_file=()
    wm_of_file=()
    while IFS= read -r line; do
      file=${line%%:*}
      key=${line#*:}
      value=${key#*=}
      key=${key%%=*}
      [[ -n $value ]] || continue
      case $key in
        Icon) [[ -n ${icon_of_file[$file]+x} ]] || icon_of_file[$file]=$value ;;
        StartupWMClass) wm_of_file[$file]=$value ;;
      esac
    done < <(grep -H -E '^(Icon|StartupWMClass)=' "${files[@]}" 2>/dev/null)

    # APP_DIRS is ordered by precedence, so first write wins.
    for file in "${!icon_of_file[@]}"; do
      stem=${file##*/}
      stem=${stem%.desktop}
      [[ -n ${icon_by_class[$stem]+x} ]] || icon_by_class[$stem]=${icon_of_file[$file]}
      wm=${wm_of_file[$file]:-}
      [[ -n $wm && -z ${icon_by_class[$wm]+x} ]] && icon_by_class[$wm]=${icon_of_file[$file]}
    done
  done

  mkdir -p "${ICON_CACHE%/*}" 2>/dev/null
  {
    for key in "${!icon_by_class[@]}"; do
      printf '%s\t%s\n' "$key" "${icon_by_class[$key]}"
    done
  } > "$ICON_CACHE" 2>/dev/null
}

if (( ROFI_RETV == INITIAL_CALL )); then
  printf '\0prompt\x1f\uf2d2\n'
  printf '\0use-hot-keys\x1ftrue\n'

  populate_app_dirs
  icon_cache_stale && build_icon_cache
  [[ -e $ICON_CACHE ]] || : > "$ICON_CACHE" 2>/dev/null

  # jq emits the rofi protocol itself and joins the icon map, so there is no
  # per-window shell loop.
  hyprctl clients -j | jq -j --rawfile icons "$ICON_CACHE" '
    ($icons | split("\n") | map(select(length > 0) | split("\t") | {(.[0]): .[1]}) | add // {}) as $icon_map
    | sort_by(.focusHistoryID)[]
    | select(.focusHistoryID != 0)
    | (.class // "") as $class
    | .title, "\u0000icon\u001f", ($icon_map[$class] // $class), "\u001finfo\u001f", .address, "\n"
  '
  exit 0
fi

# coproc keeps the dispatch attached; otherwise focus moves the cursor but does
# not focus the window.
case "$ROFI_RETV" in
  "$DEFAULT_SELECT")
    coproc hyprctl dispatch "hl.dsp.focus({ window = \"address:$ROFI_INFO\" })" >/dev/null 2>&1
    ;;
  "$CUSTOM_BIND_1")
    coproc hyprctl dispatch "hl.dsp.window.move({ workspace = \"$(hyprctl activeworkspace -j | jq -r .id)\", window = \"address:$ROFI_INFO\" })" >/dev/null 2>&1
    ;;
esac

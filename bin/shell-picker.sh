#!/usr/bin/env bash

# Define shell options: key | label | color | command
options=(
  "b| Bash|#45B052|bash"
  "z|% Zsh|#F15A1F|zsh"
  "p| PowerShell|#0078D4|pwsh"
  "f| Fish|#4A9CC9|fish"
  "n| Nushell|#3DD68C|nu"
)

RESET='\033[0m'
HIDE_CURSOR='\033[?25l'
SHOW_CURSOR='\033[?25h'

printf "$HIDE_CURSOR"

hex_to_ansi() {
  local hex="${1#"#"}"
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  printf '\033[38;2;%d;%d;%dm' "$r" "$g" "$b"
}

for entry in "${options[@]}"; do
  IFS='|' read -r key label color command <<< "$entry"
  ansi_color=$(hex_to_ansi "$color")
  printf "  [%s] %b%s%b\n" "$key" "$ansi_color" "$label" "$RESET"
done

read -rsn1 keypress

declare DEFAULT

for entry in "${options[@]}"; do
  IFS='|' read -r key label color command <<< "$entry"
  if [[ "$keypress" == "\n" ]]; then
    DEFAULT=true
    break
  fi
  if [[ "$keypress" == "$key" ]]; then
    clear
    printf "$SHOW_CURSOR"
    exec $command
  fi
done

clear && printf "$SHOW_CURSOR"
$DEFAULT \
  && echo -e "Launching default shell, $(basename "$SHELL")" \
  || echo -e "No shell associated with '$keypress', defaulting to $(basename "$SHELL")"
exec $(basename "$SHELL")

#!/bin/sh
cd ~ || exit
file="$(fzf --walker file,dir,hidden --prompt='Open in Neovim > ' --scheme=path)"

if [ -z "${file}" ]; then exit; fi

if [ -d "${file}" ]; then
  cd "$file" || exit
else
  cd "$(dirname "$file")" || exit
fi

neovide --fork -- --embed "$(basename "$file")"

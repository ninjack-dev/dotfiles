#!/usr/bin/env bash

# $1 - {project} Project path
# $2 - {file}    Filename
# $3 - {line}    File line
# $4 - {col}     File collumn

# Define the named pipe
SOCKET="$1/godot-nvim.sock" # Put the socket in the project directory for ease of use

if [ ! -S "$SOCKET" ]; then 
  neovide --fork -- --listen "$SOCKET" -c "cd $1" "$2"
fi

nvim --server "$SOCKET" --remote-send "<ESC>:e $2<CR>:call cursor($3,$4)<CR>"

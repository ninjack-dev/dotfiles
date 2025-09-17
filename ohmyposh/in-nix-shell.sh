#!/usr/bin/env bash

if [[ -n $IN_NIX_SHELL ]]; then
  echo -n "$IN_NIX_SHELL"
  exit 0
fi

readarray -t -d ':' path_elements <<< $PATH

declare CHAIN_BEGUN=0
for path in "${path_elements[@]}"; do
  if [[ $CHAIN_BEGUN -eq 0 && "$path" =~ /nix/store/.* ]]; then
    CHAIN_BEGUN=1
    continue
  fi
  if [[ $CHAIN_BEGUN -eq 1  && ! "$path" =~ /nix/store/.* ]]; then
    echo -n "new"
    exit 0
  fi
done
exit 1

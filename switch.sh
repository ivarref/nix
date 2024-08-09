#!/usr/bin/env bash

if [ "$#" -eq 1 ]; then
  echo "Running darwin-rebuild ..."
  darwin-rebuild switch --flake $HOME/.config/nix
  echo "darwin-rebuild exited: $?"
else
  printf "flake.nix\n" | entr -c ./switch.sh --do-it
fi

#!/usr/bin/env bash

if [ "$#" -eq 1 ]; then
  echo "Running darwin-rebuild ..."
  darwin-rebuild switch --flake $HOME/.config/nix
  echo "darwin-rebuild exited: $?"
else
  printf "$HOME/.config/nix/flake.nix\n" | entr -c $HOME/.config/nix/switch.sh --do-it
fi

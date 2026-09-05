#!/bin/env bash

set -e

USER_NAME=$(id -un)

# nix run github:nix-community/home-manager -- switch --flake /home/$USER_NAME#$USER_NAME

export NIX_CONFIG="experimental-features = nix-command flakes"

home-manager switch --impure --flake "/home/$USER_NAME#$USER_NAME"

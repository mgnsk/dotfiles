#!/bin/env bash

set -e

USER_NAME=$(id -un)

# nix run github:nix-community/home-manager -- switch --flake /home/$USER_NAME#$USER_NAME

export NIX_CONFIG="experimental-features = nix-command flakes"

home-manager switch --impure --flake "/home/$USER_NAME#$USER_NAME"

# Keep /run/opengl-driver pointed at this generation's GPU libs on non-NixOS
# systems (see flake.nix targets.genericLinux.enable comment).
gpu_setup=$(readlink -f "$HOME/.nix-profile/bin/non-nixos-gpu-setup" 2>/dev/null || true)
if [[ -n "$gpu_setup" ]]; then
	sudo "$gpu_setup"
fi

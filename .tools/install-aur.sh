#!/usr/bin/env bash

set -euo pipefail

find "$HOME/.cache/aur" -type f -iname "*.zst" -exec sudo pacman -U --noconfirm --needed {} \;

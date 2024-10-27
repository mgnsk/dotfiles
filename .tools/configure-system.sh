#!/usr/bin/env bash

set -euo pipefail

# Generate locales.
echo "en_US.UTF-8 UTF-8" | sudo tee /etc/locale.gen
echo "LANG=en_US.UTF-8" | sudo tee /etc/locale.conf
sudo locale-gen

mkdir -p ~/.config/fish/completions
rustup completions fish >~/.config/fish/completions/rustup.fish

fish -c "fish_update_completions"

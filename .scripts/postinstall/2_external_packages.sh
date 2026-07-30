#!/bin/env bash

set -eu

# Install yay.
yaydir="$HOME/.cache/yay-bin"
if [ -d "$yaydir" ]; then
	git -C "$yaydir" pull
else
	git clone https://aur.archlinux.org/yay-bin.git "$yaydir"
fi
makepkg -D "$yaydir" -si --needed

# Install AUR packages.
packages=(
	1password
	1password-cli
	brave-origin-bin
	downgrade
	libdigidoccpp
	obmenu-generator
	qdigidoc4
	web-eid-chrome
	web-eid-firefox
)

yay -S "${packages[@]}"

sudo systemctl enable pcscd.socket

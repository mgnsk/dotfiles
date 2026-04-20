#!/bin/env bash

set -eu

# Install yay.
yaydir="/tmp/yay-bin"
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
	brave-bin
	downgrade
	obmenu-generator
	raysession
	snapd-xdg-open-git
	wdisplays
	libdigidoccpp
	qdigidoc4
	web-eid
)

yay -S "${packages[@]}"

sudo systemctl enable pcscd.socket

#!/bin/env bash

set -eu

# Run as normal user after booting into an installed system.

packages=(
	# System.
	mesa
	base-devel
	realtime-privileges
	flatpak
	tailscale
	nix
	docker
	docker-buildx
	docker-compose
	pacman-contrib
	ufw
	logrotate
	vulkan-tools
	fwupd
	inetutils # provides hostname
	openssh

	# Bluetooth.
	bluez
	bluez-utils

	# CLI tools.
	git # also nix-managed, but useful when bootstrapping a fresh system before nix
	vim # also nix-managed, but useful when bootstrapping a fresh system before nix
	kconfig # provides kwriteconfig6
	arch-audit
	reflector
	bubblewrap
	passt

	# Identity and passwords.
	kwallet
	kwalletmanager
	kwallet-pam

	# Desktop and window management.
	# swaylock needs a PAM service file at /etc/pam.d/swaylock to authenticate against your password.
	# Arch's pacman package for swaylock ships that file as part of the package.
	# The Nix-built swaylock is just a binary — home-manager doesn't (and can't, on a non-NixOS system) install anything into /etc/pam.d.
	swaylock
	mate-polkit

	# Power management.
	tlp
	tlpui
	smartmontools

	# Xorg and Openbox (for TTY2).
	xorg-server
	xorg-xinit
	openbox

	# Printing.
	cups
	cups-pdf
	ipp-usb
	nss-mdns

	# iOS.
	libimobiledevice
	usbmuxd
)

if lscpu | grep -q Intel; then
	echo "Detected Intel CPU"
	packages+=(
		intel-ucode
		intel-media-driver
		vulkan-intel
	)
elif lscpu | grep -q AMD; then
	echo "Detected AMD CPU"
	packages+=(
		amd-ucode
		vulkan-radeon
	)
else
	echo "Unsupported CPU!"
	exit 1
fi

# Install packages.
sudo pacman -S --needed --noconfirm "${packages[@]}"

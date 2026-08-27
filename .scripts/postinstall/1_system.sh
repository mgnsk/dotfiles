#!/bin/env bash

set -eu

# Run as normal user after booting into an installed system.

packages=(
	# System.
	man-db
	mesa
	base-devel
	bash-completion
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

	# Bluetooth.
	bluez
	bluez-utils
	blueman

	# CLI tools.
	inotify-tools
	git
	less
	vim
	grim
	slurp
	zenity
	rsync
	glances
	fzf
	kconfig # provides kwriteconfig6
	qrencode
	patchelf
	iotop
	powertop
	arch-audit
	reflector
	bubblewrap
	passt

	# Identity and passwords.
	kwallet
	kwalletmanager
	kwallet-pam

	# Desktop and window management.
	sway
	swaybg
	swaylock
	swayidle
	swaync
	libnotify
	waybar
	wl-clipboard
	mate-polkit
	xorg-xwayland
	j4-dmenu-desktop
	wmenu
	wdisplays
	nm-connection-editor
	network-manager-applet
	gammastep
	xdg-desktop-portal-wlr
	xdg-desktop-portal-gtk
	xdg-user-dirs
	pavucontrol
	noto-fonts
	noto-fonts-cjk
	noto-fonts-emoji
	noto-fonts-extra
	otf-font-awesome
	kitty
	alacritty
	foot
	geany
	archlinux-xdg-menu
	wayvnc

	# Multimedia.
	vmpk
	mpv
	smplayer
	picard
	handbrake
	yt-dlp
	whipper
	gimp
	inkscape

	# Power management.
	tlp
	tlpui
	smartmontools

	# Web and document tools.
	thunderbird
	libreoffice-fresh
	libreoffice-fresh-et
	firefox
	librewolf
	profile-sync-daemon

	# File management.
	qt6ct
	dolphin
	kde-cli-tools
	kdegraphics-thumbnailers
	kimageformats
	qt6-imageformats
	ffmpegthumbs
	ark
	unrar
	webp-pixbuf-loader
	gthumb
	rclone
	baobab
	gnome-disk-utility

	# Xorg and Openbox (for TTY2).
	xorg-server
	xorg-xinit
	openbox
	tint2
	picom
	arandr

	# Printing.
	cups
	cups-pdf
	ipp-usb
	nss-mdns

	# iOS.
	libimobiledevice
	usbmuxd

	# Audio.
	reaper
	reapack
	qjackctl
	fluidsynth
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

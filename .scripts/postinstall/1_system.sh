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
	wget
	fwupd
	lsof

	# Bluetooth.
	bluez
	bluez-utils
	blueman

	# CLI tools.
	strace
	inotify-tools
	sshfs
	git
	less
	tree
	fd
	ripgrep
	bat
	sox
	vim
	tmux
	glances
	grim
	slurp
	zenity
	fzf
	rsync
	vivid
	bind
	stress
	iotop
	direnv
	xdg-dbus-proxy

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
	cantarell-fonts
	otf-font-awesome
	kitty
	alacritty
	foot
	geany
	archlinux-xdg-menu
	wayvnc

	# Power management.
	tlp
	smartmontools

	# Web and document tools.
	thunderbird
	libreoffice-fresh
	libreoffice-fresh-et
	firefox
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
	7zip
	exiftool
	webp-pixbuf-loader
	gthumb
	rclone
	imagemagick
	baobab
	mpv
	smplayer
	yt-dlp
	fdupes
	cuetools
	picard
	gnome-disk-utility
	handbrake

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

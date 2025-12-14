#!/bin/env bash

set -eu

# Run as normal user after booting into an installed system.

packages=(
	# System.
	man-db
	fuse2
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
	snap-pac
	pacman-contrib
	ufw
	logrotate
	ntfs-3g
	vulkan-tools
	wget

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
	neovim
	tree-sitter-cli
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
	jq
	iotop
	shfmt
	direnv
	xdg-dbus-proxy
	winetricks

	# Disks.
	btrfs-assistant
	qt6-wayland

	# Identity and passwords.
	pinentry
	gcr
	keepassxc
	qt5-wayland

	# Desktop and window management.
	sway
	swaybg
	swaylock
	swayidle
	swaync
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
	thunar
	thunar-archive-plugin
	engrampa
	unrar
	7zip
	tumbler
	ffmpegthumbnailer
	exiftool
	gvfs
	webp-pixbuf-loader
	viewnior
	gthumb
	geeqie
	rclone
	imagemagick
	baobab
	mpv
	smplayer
	yt-dlp
	fdupes

	# Xorg and Openbox (for TTY2).
	xorg-server
	xorg-xinit
	openbox
	tint2
	picom

	# Printing.
	cups
	cups-pdf
	ipp-usb
	nss-mdns

	# iOS.
	libimobiledevice
	usbmuxd
	gvfs-gphoto2
	gvfs-afc

	# Go development.
	go
	gopls
	revive

	# Rust development.
	rustup

	# Lua development.
	lua-language-server
	luacheck
	stylua

	# PHP development.
	php
	composer

	# Python development.
	python-black
	python-pylint
	uv

	# Web development.
	tidy
	npm
	pnpm
	eslint
	prettier
	stylelint
	typescript
	bash-language-server
	markdownlint-cli
	npm-check-updates
	vscode-css-languageserver
	vscode-html-languageserver
	yaml-language-server

	# General development.
	buf
	yamllint
	github-cli
	glow
	asciinema
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

#!/bin/env bash

set -eu

# Run as normal user after booting into an installed system.

function set_option() {
	file="$1"
	key="$2"
	value="$3"
	script=$(printf 's/#*%s=.*/%s=%s/' "$key" "$key" "$value")
	sudo sed -i "$script" "$file"
}

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
	neovim
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

# Backup /boot partition data.
# https://wiki.archlinux.org/title/System_backup#Snapshots_and_/boot_partition
sudo mkdir -p /etc/pacman.d/hooks
cat <<-'EOF' | sudo tee /etc/pacman.d/hooks/55-bootbackup_pre.hook >/dev/null
	[Trigger]
	Operation = Upgrade
	Operation = Install
	Operation = Remove
	Type = Path
	Target = usr/lib/modules/*/vmlinuz

	[Action]
	Depends = rsync
	Description = Backing up pre /boot...
	When = PreTransaction
	Exec = /usr/bin/bash -c 'rsync -a --mkpath --delete /boot/ "/.bootbackup/$(date +%Y_%m_%d_%H.%M.%S)_pre"/'
EOF
cat <<-'EOF' | sudo tee /etc/pacman.d/hooks/95-bootbackup_post.hook >/dev/null
	[Trigger]
	Operation = Upgrade
	Operation = Install
	Operation = Remove
	Type = Path
	Target = usr/lib/modules/*/vmlinuz

	[Action]
	Depends = rsync
	Description = Backing up post /boot...
	When = PostTransaction
	Exec = /usr/bin/bash -c 'rsync -a --mkpath --delete /boot/ "/.bootbackup/$(date +%Y_%m_%d_%H.%M.%S)_post"/'
EOF

# Enable logrotate.
sudo systemctl enable logrotate.timer

# Ensure automatic timeline snapshotting is disabled.
sudo systemctl disable snapper-timeline.timer

# Ensure automatic snapper cleanup enabled.
sudo systemctl enable snapper-cleanup.timer

if [[ -f /etc/snapper/configs/root ]]; then
	# Keep 30 last snapshots.
	set_option /etc/snapper/configs/root NUMBER_LIMIT '"30"'
fi

# Performance settings for LUKS on SSD.
# Determine the LUKS device name.
cryptdevice=$(lsblk --list | awk '$6 == "crypt" {print $1}')
# Only enable settings on LUKS2.
if sudo cryptsetup status "$cryptdevice" | grep -q "LUKS2"; then
	if ! sudo cryptsetup status "$cryptdevice" | grep -q 'discards no_read_workqueue no_write_workqueue'; then
		sudo cryptsetup --perf-no_read_workqueue --perf-no_write_workqueue --allow-discards --persistent refresh "$cryptdevice"
	fi
fi

# Enable periodic SSD trim.
sudo systemctl enable fstrim.timer

# Disable file access time to improve SSD lifetime.
sudo sed -i -e 's/relatime/noatime/g' /etc/fstab

# Set up power options.
cat <<-'EOF' | sudo tee /etc/udev/rules.d/99-lowbat.rules >/dev/null
	# Suspend the system when battery level drops to 5% or lower
	SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[0-5]", RUN+="/usr/bin/systemctl suspend"
EOF

sudo sensors-detect --auto

sudo systemctl enable tlp.service
sudo systemctl mask systemd-rfkill.service
sudo systemctl mask systemd-rfkill.socket

# Create user dirs.
xdg-user-dirs-update

# Enable realtime privileges for user.
sudo gpasswd -a "$USER" realtime

# Set up docker.
sudo systemctl enable docker.socket
sudo gpasswd -a "$USER" docker

# Set up nix.
sudo systemctl enable nix-daemon.service
if ! nix-channel --list | grep -q 'channels'; then
	nix-channel --add https://nixos.org/channels/nixpkgs-unstable
	nix-channel --update
fi
cat <<-'EOF' | sudo tee /etc/nix/nix.conf >/dev/null
	build-users-group = nixbld
	max-jobs = auto
EOF

# Disable tailscale logs.
cat <<-'EOF' | sudo tee /etc/default/tailscaled >/dev/null
	# Set the port to listen on for incoming VPN packets.
	# Remote nodes will automatically be informed about the new port number,
	# but you might want to configure this in order to set external firewall
	# settings.
	PORT="41641"

	# Extra flags you might want to pass to tailscaled.
	FLAGS=""

	TS_NO_LOGS_NO_SUPPORT=true
EOF

# Set up tailscale.
sudo systemctl enable --now tailscaled.service
if tailscale status --json | grep -q 'NeedsLogin'; then
	echo "Logging into tailscale"
	sudo tailscale set --operator="$USER"
	tailscale up --qr
fi

# Enable ssh-agent.
systemctl --user enable ssh-agent.service

# Set up dotfiles.
if [[ ! -d "$HOME/.git" ]]; then
	git clone --recurse-submodules --separate-git-dir="$HOME/.git" https://github.com/mgnsk/dotfiles.git "$HOME/dotfiles-tmp"
	git config status.showUntrackedFiles no
	git reset --hard --recurse-submodules origin/master
	rm -rf "$HOME/dotfiles-tmp"
fi

# Set up rust.
rustup update
rustup default stable
rustup component add rust-analyzer

# Set up PHP.
sudo sed -i -e 's/;extension=iconv/extension=iconv/g' /etc/php/php.ini

# 1password signing key.
gpg --keyserver keyserver.ubuntu.com --recv-keys 3FEF9748469ADBE15DA7CA80AC2D62742012EA22

# phpstan-bin signing key.
gpg --keyserver keys.openpgp.org --recv-keys 51C67305FFC2E5C0

# TODO pkgbuilds
# jsfx-lint

# Install AUR packages.
packages=(
	1password
	1password-cli
	brave-bin
	downgrade
	gojq-bin
	go-jsonnet
	hadolint-bin
	helm-ls-bin
	jsonnet-language-server
	nil-git
	nixfmt
	perl-linux-desktopfiles # Dependency of obmenu-generator.
	obmenu-generator
	phpactor-bin
	phpstan-bin
	raysession
	rclone-browser
	shellcheck-bin
	snap-pac-grub
	wdisplays
	wine-tkg-staging-wow64-bin
	yay-bin
)

for pkg in "${packages[@]}"; do
	makepkg -D "$HOME/.pkgbuilds/$pkg" -si --needed
done

# Install support for Estonian ID card.
packages=(
	libdigidocpp
	qdigidoc4
	web-eid
)

# Estonian ID card signing key.
gpg --keyserver keyserver.ubuntu.com --recv-keys 90C0B5E75C3B195D

for pkg in "${packages[@]}"; do
	makepkg -D "$HOME/.pkgbuilds/$pkg" -si --needed
done

sudo systemctl enable pcscd.socket

# Install JS packages.
(
	cd ~/.npm-packages
	npm ci
)

# Install Go packages.
(
	cd ~/.go-packages
	go install tool
)

# Enable saving the last booted entry in GRUB.
if grep -q 'GRUB_DEFAULT=0' /etc/default/grub; then
	set_option /etc/default/grub GRUB_DEFAULT saved
	set_option /etc/default/grub GRUB_SAVEDEFAULT true
	sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

# Configure profile-sync-daemon for brave.
cat <<-'EOF' | sudo tee /usr/share/psd/browsers/brave >/dev/null
	DIRArr[0]="$XDG_CONFIG_HOME/BraveSoftware/Brave-Browser"
	PSNAME="brave"
EOF

# Enable profile-sync-daemon.
line="$USER ALL=(ALL) NOPASSWD: /usr/bin/psd-overlay-helper"
if ! sudo grep -q "$line" /etc/sudoers; then
	echo "$line" | sudo tee -a /etc/sudoers
fi
systemctl --user enable psd.service

# Disable automatic coredumps.
sudo mkdir -p /etc/systemd/coredump.conf.d
cat <<-'EOF' | sudo tee /etc/systemd/coredump.conf.d/custom.conf >/dev/null
	[Coredump]
	Storage=none
	ProcessSizeMax=0
EOF

# Enable printing support.
sudo systemctl enable cups.socket

# Increase max AIO nr.
cat <<-'EOF' | sudo tee /etc/sysctl.d/80-aio.conf >/dev/null
	fs.aio-max-nr = 1048576
EOF

# Configure firewall.
sudo systemctl enable ufw.service
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on tailscale0
sudo ufw enable
sudo ufw logging off

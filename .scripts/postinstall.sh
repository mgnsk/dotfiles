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
	man-db
	fuse2
	mesa
	mpv
	yt-dlp
	sox
	base-devel
	strace
	inotify-tools
	sshfs
	git
	less
	tree
	fd
	fdupes
	bash-completion
	neovim
	tmux
	realtime-privileges
	glances
	noto-fonts
	noto-fonts-cjk
	noto-fonts-emoji
	noto-fonts-extra
	cantarell-fonts
	otf-font-awesome
	gnome-tweaks
	baobab
	xdg-desktop-portal-wlr
	xdg-desktop-portal-gtk
	xdg-user-dirs
	flatpak
	sway
	swaybg
	swaylock
	swayidle
	swaync
	waybar
	wl-clipboard
	mate-polkit
	geoclue
	gammastep
	nm-connection-editor
	network-manager-applet
	viewnior
	webp-pixbuf-loader
	grim
	slurp
	zenity
	imagemagick
	pavucontrol
	j4-dmenu-desktop
	wmenu
	kitty
	alacritty
	foot
	thunar
	thunar-archive-plugin
	engrampa
	unrar
	7zip
	tumbler
	ffmpegthumbnailer
	geany
	gvfs
	tlp
	smartmontools
	tailscale
	nix
	docker
	docker-buildx
	docker-compose
	thunderbird
	profile-sync-daemon
	fzf
	rsync
	vivid
	xorg-xwayland
	xorg-server
	xorg-xinit
	openbox
	tint2
	picom
	bind
	gimp
	qbittorrent
	libreoffice-fresh
	libreoffice-fresh-et
	picard
	firefox
	keepassxc
	qt5-wayland
	qt6-wayland
	snap-pac
	stress
	cups
	cups-pdf
	ipp-usb
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

# Install AUR packages.
packages=(
	1password
	1password-cli
	btrfs-assistant
	obmenu-generator
	snap-pac-grub
	swaddle
	sway-fader
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

for pkg in "${packages[@]}"; do
	makepkg -D "$HOME/.pkgbuilds/$pkg" -si --needed
done

sudo systemctl enable --now pcscd.socket

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

# Ensure automatic timeline snapshotting is disabled.
sudo systemctl disable --now snapper-timeline.timer

# Ensure automatic snapper cleanup enabled.
sudo systemctl enable --now snapper-cleanup.timer

if [[ -f /etc/snapper/configs/root ]]; then
	# Keep 30 last snapshots.
	set_option /etc/snapper/configs/root NUMBER_LIMIT '"30"'
fi

# Performance settings for LUKS on SSD.
# Determine the LUKS device name.
cryptdevice=$(lsblk --list | awk '$6 == "crypt" {print $1}')
# Only enable settings on LUKS2.
if sudo cryptsetup status "$cryptdevice" | grep -q "LUKS2"; then
	if sudo cryptsetup status "$cryptdevice" | grep -q 'discards no_read_workqueue no_write_workqueue'; then
		true
	else
		sudo cryptsetup --perf-no_read_workqueue --perf-no_write_workqueue --allow-discards --persistent refresh "$cryptdevice"
		sudo systemctl enable --now fstrim.timer
	fi
fi

# Disable file access time to improve SSD lifetime.
sudo sed -i -e 's/relatime/noatime/g' /etc/fstab

# Set up power options.
cat <<-'EOF' | sudo tee /etc/udev/rules.d/99-lowbat.rules >/dev/null
	# Suspend the system when battery level drops to 5% or lower
	SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[0-5]", RUN+="/usr/bin/systemctl suspend"
EOF

sudo systemctl enable --now tlp
sudo systemctl mask systemd-rfkill.service
sudo systemctl mask systemd-rfkill.socket

# Create user dirs.
xdg-user-dirs-update

# Set default browser.
(
	cd /usr/share/applications
	xdg-settings set default-web-browser firefox.desktop
)

# Enable realtime privileges for user.
sudo gpasswd -a "$USER" realtime

# Add to audio group. TODO: is this necessary anymore?
sudo gpasswd -a "$USER" audio

# Set up docker.
sudo systemctl enable --now docker
sudo gpasswd -a "$USER" docker

# Set up nix.
sudo systemctl enable --now nix-daemon
if nix-channel --list | grep -q 'nixpkgs-unstable'; then
	true
else
	nix-channel --add https://nixos.org/channels/nixpkgs-unstable
	nix-channel --update
fi
cat <<-'EOF' | sudo tee /etc/nix/nix.conf >/dev/null
	build-users-group = nixbld
	max-jobs = auto
EOF

# Set up tailscale.
sudo systemctl enable --now tailscaled
if tailscale status --json | grep -q 'NeedsLogin'; then
	echo "Logging into tailscale"
	sudo tailscale set --operator="$USER"
	tailscale up --qr
fi

# Set up dotfiles.
if [[ ! -d "$HOME/.git" ]]; then
	echo "Set up Github SSH keys and press a key to continue..."
	read -r

	git clone --recurse-submodules --separate-git-dir="$HOME/.git" git@github.com:mgnsk/dotfiles.git "$HOME/dotfiles-tmp"
	git config status.showUntrackedFiles no
	git reset --hard --recurse-submodules origin/master
	rm -rf "$HOME/dotfiles-tmp"
fi

# Enable saving the last booted entry in GRUB.
if grep -q 'GRUB_DEFAULT=0' /etc/default/grub; then
	set_option /etc/default/grub GRUB_DEFAULT saved
	set_option /etc/default/grub GRUB_SAVEDEFAULT true
	sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

# Enable profile-sync-daemon.
line="$USER ALL=(ALL) NOPASSWD: /usr/bin/psd-overlay-helper"
if sudo grep -q "$line" /etc/sudoers; then
	true
else
	echo "$line" | sudo tee -a /etc/sudoers
fi
systemctl --user enable --now psd

# Disable automatic coredumps.
sudo mkdir -p /etc/systemd/coredump.conf.d
cat <<-'EOF' | sudo tee /etc/systemd/coredump.conf.d/custom.conf >/dev/null
	[Coredump]
	Storage=none
	ProcessSizeMax=0
EOF

# Enable ssh-agent.
systemctl --user enable --now ssh-agent

# Enable printing support.
sudo systemctl enable --now cups

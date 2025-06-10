#!/bin/env bash

set -euo pipefail

function set_option() {
	file="$1"
	key="$2"
	value="$3"
	script=$(printf 's/#*%s=.*/%s=%s/' "$key" "$key" "$value")
	sudo sed -i "$script" "$file"
}

# Run as normal user after booting into an installed system.

# Install packages.
sudo pacman -S --needed --noconfirm \
	amd-ucode \
	intel-ucode \
	mesa \
	vulkan-radeon \
	intel-media-driver \
	vulkan-intel \
	mpv \
	yt-dlp \
	base-devel \
	git \
	less \
	tree \
	bash-completion \
	vim \
	tmux \
	realtime-privileges \
	glances \
	noto-fonts \
	noto-fonts-cjk \
	noto-fonts-emoji \
	noto-fonts-extra \
	cantarell-fonts \
	ttf-font-awesome \
	xfce4-settings \
	xdg-desktop-portal-wlr \
	xdg-desktop-portal-gtk \
	xdg-user-dirs \
	flatpak \
	sway \
	swaybg \
	swaylock \
	swayidle \
	swaync \
	waybar \
	lxsession \
	geoclue \
	gammastep \
	xorg-xwayland \
	nm-connection-editor \
	network-manager-applet \
	gnome-keyring \
	libsecret \
	seahorse \
	viewnior \
	grim \
	slurp \
	imagemagick \
	pavucontrol \
	j4-dmenu-desktop \
	wmenu \
	kitty \
	thunar \
	tumbler \
	ffmpegthumbnailer \
	gvfs \
	cpupower \
	tailscale \
	nix \
	docker \
	docker-buildx \
	docker-compose \
	thunderbird \
	profile-sync-daemon \
	fzf \
	rsync

# Set up yay.
yaydir="$HOME/workspaces/yay-bin"
mkdir -p "$yaydir"
if [[ ! -d "$yaydir/.git" ]]; then
	cd "$yaydir"
	git clone https://aur.archlinux.org/yay-bin.git .
	makepkg -si
fi

# Set up BTRFS snapshots.
if [[ "$(stat -f -c %T /)" == "btrfs" ]]; then
	sudo pacman -S --needed --noconfirm \
		qt6-wayland \
		snap-pac

	yay -S --needed --noconfirm \
		snap-pac-grub \
		btrfs-assistant-git

	# Ensure automatic timeline snapshotting is disabled.
	sudo systemctl disable --now snapper-timeline.timer

	# Keep 10 last snapshots.
	set_option /etc/snapper/configs/root NUMBER_LIMIT '"10"'

	# Include /boot partition data in snapshots.
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
fi

# Set up AUR packages.
yay -S --needed --noconfirm \
	themix-full-git \
	swaddle \
	librewolf-bin \
	profile-sync-daemon-librewolf

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
# Note: refer to https://linrunner.de/tlp/settings/processor.html#processor for explanation for different scaling driver modes.
# Both amd-pstate and intel_pstate with powersave governor may still reach max frequency.
# This is similar to the ondemand governor in the old acpi-cpufreq driver.
# Also read https://wiki.archlinux.org/title/CPU_frequency_scaling#Scaling_governors which says that
# the powersave governor on *_pstate drivers is equivalent to schedutil on old driver.
if sudo cpupower frequency-info | grep -q pstate; then
	set_option /etc/default/cpupower governor "'powersave'"
elif sudo cpupower frequency-info | grep available | grep -q schedutil; then
	set_option /etc/default/cpupower governor "'schedutil'"
else
	echo "Check CPU scaling governor!"
fi
sudo systemctl enable --now cpupower

# Create user dirs.
xdg-user-dirs-update

# Enable realtime privileges for user.
sudo gpasswd -a "$USER" realtime

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

# Set up auto unlock option for keyring.
cat <<-'EOF' | sudo tee /etc/pam.d/login >/dev/null
	#%PAM-1.0

	auth       requisite    pam_nologin.so
	auth       include      system-local-login
	auth       optional     pam_gnome_keyring.so
	account    include      system-local-login
	session    include      system-local-login
	session    optional     pam_gnome_keyring.so auto_start
	password   include      system-local-login
EOF

# Enable profile-sync-daemon.
line="$USER ALL=(ALL) NOPASSWD: /usr/bin/psd-overlay-helper"
if sudo grep -q "$line" /etc/sudoers; then
	true
else
	echo "$line" | sudo tee -a /etc/sudoers
fi
systemctl --user enable --now psd

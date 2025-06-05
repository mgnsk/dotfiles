#!/bin/env bash

set -euo pipefail

# Run as normal user after booting into an installed system.

# Performance settings for LUKS on SSD.
if sudo cryptsetup status root | grep -q 'discards no_read_workqueue no_write_workqueue'; then
	true
else
	sudo cryptsetup --perf-no_read_workqueue --perf-no_write_workqueue --allow-discards --persistent refresh root
	sudo systemctl enable --now fstrim.timer
fi

# Disable file access time to improve SSD lifetime.
sudo sed -i -e 's/relatime/noatime/g' /etc/fstab

# Enable saving the last booted entry in GRUB.
if grep -q 'GRUB_DEFAULT=0' /etc/default/grub; then
	sudo sed -i -e 's/GRUB_DEFAULT=0/GRUB_DEFAULT=saved/g' /etc/default/grub
	sudo sed -i -e 's/#GRUB_SAVEDEFAULT=true/GRUB_SAVEDEFAULT=true/g' /etc/default/grub
	sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

sudo pacman -S --needed --noconfirm \
	amd-ucode \
	base-devel \
	git \
	less \
	bash-completion \
	vim \
	tmux \
	realtime-privileges \
	glances \
	noto-fonts \
	cantarell-fonts \
	ttf-font-awesome \
	xfce4-settings \
	xdg-desktop-portal-wlr \
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
	viewnior \
	grim \
	slurp \
	imagemagick \
	pavucontrol \
	j4-dmenu-desktop \
	wmenu \
	kitty \
	thunar \
	cpupower \
	tailscale \
	nix \
	docker \
	docker-buildx \
	docker-compose \
	thunderbird

# Enable realtime privileges for user.
sudo gpasswd -a "$USER" realtime

# Set up docker.
sudo systemctl enable --now docker
sudo gpasswd -a "$USER" docker

# Set up nix.
sudo systemctl enable --now nix-daemon
nix-channel --add https://nixos.org/channels/nixpkgs-unstable
nix-channel --update

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

# Set up yay.
yaydir="$HOME/workspaces/yay-bin"
mkdir -p "$yaydir"
if [[ ! -d "$yaydir/.git" ]]; then
	cd "$yaydir"
	git clone https://aur.archlinux.org/yay-bin.git .
	makepkg -si
fi

# Set up AUR packages.
yay -S --needed --noconfirm \
	themix-full-git \
	swaddle

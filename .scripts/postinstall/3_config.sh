#!/bin/env bash

set -eu

function set_option() {
	file="$1"
	key="$2"
	value="$3"

	sudo kwriteconfig6 --file "$file" --group "<default>" --key "$key" "$value"
}

# Enable systemd journal in RAM.
set_option /etc/systemd/journald.conf Storage volatile

# Enable sleep when external monitor connected.
set_option /etc/systemd/logind.conf HandleLidSwitchDocked suspend

# Enable logrotate.
sudo systemctl enable logrotate.timer

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

cat <<-'EOF' | sudo tee /etc/udev/rules.d/50-evoluent-no-autosuspend.rules >/dev/null
	# Disable USB autosuspend for Evoluent VerticalMouse.
	ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1a7c", ATTR{idProduct}=="0195", TEST=="power/control", ATTR{power/control}="on"
EOF

sudo sensors-detect --auto

# Configure power options.
set_option /etc/tlp.conf START_CHARGE_THRESH_BAT0 70
set_option /etc/tlp.conf STOP_CHARGE_THRESH_BAT0 80

sudo systemctl enable tlp.service
sudo systemctl mask systemd-rfkill.service
sudo systemctl mask systemd-rfkill.socket

# Enable realtime privileges for user.
sudo gpasswd -a "$USER" realtime

# Set up docker.
sudo systemctl enable docker.socket
sudo gpasswd -a "$USER" docker

# Set up nix.
cat <<-'EOF' | sudo tee /etc/nix/nix.conf >/dev/null
	build-users-group = nixbld
	max-jobs = 1
	cores = 0
EOF
sudo systemctl enable nix-daemon.service

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

# Set up auto unlock option for keyring.
cat <<-'EOF' | sudo tee /etc/pam.d/login >/dev/null
	#%PAM-1.0

	auth       include      system-local-login
	auth       optional     pam_gnome_keyring.so
	account    include      system-local-login
	session    include      system-local-login
	session    optional     pam_gnome_keyring.so auto_start
	password   include      system-local-login
EOF

# Enable saving the last booted entry in GRUB.
set_option /etc/default/grub GRUB_DEFAULT saved
set_option /etc/default/grub GRUB_SAVEDEFAULT true

# Install and configure GRUB.
sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Enable printing support.
sudo systemctl enable cups.socket
sudo systemctl enable avahi-daemon

# Configure mdns for printing.
cat <<-'EOF' | sudo tee /etc/nsswitch.conf >/dev/null
	# Name Service Switch configuration file.
	# See nsswitch.conf(5) for details.

	passwd: files systemd
	group: files [SUCCESS=merge] systemd
	shadow: files systemd
	gshadow: files systemd

	publickey: files

	hosts: mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns
	networks: files

	protocols: files
	services: files
	ethers: files
	rpc: files

	netgroup: files
EOF

# Increase max AIO nr.
cat <<-'EOF' | sudo tee /etc/sysctl.d/80-aio.conf >/dev/null
	fs.aio-max-nr = 1048576
EOF

# Enable ntsync kernel module (Wine/Proton sync primitives).
cat <<-'EOF' | sudo tee /etc/modules-load.d/ntsync.conf >/dev/null
	ntsync
EOF
sudo modprobe ntsync

# Enable bluetooth.
sudo systemctl enable bluetooth

# Configure firewall.
sudo systemctl enable ufw.service
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on tailscale0
sudo ufw enable
sudo ufw logging off

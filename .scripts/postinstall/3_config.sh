#!/bin/env bash

set -eu

function set_option() {
	file="$1"
	key="$2"
	value="$3"
	script=$(printf 's/#*%s=.*/%s=%s/' "$key" "$key" "$value")
	sudo sed -i "$script" "$file"
}

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
cat <<-'EOF' | sudo tee /etc/nix/nix.conf >/dev/null
	build-users-group = nixbld
	max-jobs = auto
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

# Enable ssh-agent.
systemctl --user enable ssh-agent.service

# Configure KeepassXC.
crudini --set --ini-options=nospace "$HOME/.config/keepassxc/keepassxc.ini" General HideWindowOnCopy false
crudini --set --ini-options=nospace "$HOME/.config/keepassxc/keepassxc.ini" General MinimizeAfterUnlock false
crudini --set --ini-options=nospace "$HOME/.config/keepassxc/keepassxc.ini" General MinimizeOnCopy true
crudini --set --ini-options=nospace "$HOME/.config/keepassxc/keepassxc.ini" General UpdateCheckMessageShown true

crudini --set --ini-options=nospace "$HOME/.config/keepassxc/keepassxc.ini" Browser CustomProxyLocation ""
crudini --set --ini-options=nospace "$HOME/.config/keepassxc/keepassxc.ini" Browser Enabled true

crudini --set --ini-options=nospace "$HOME/.config/keepassxc/keepassxc.ini" FdoSecrets ConfirmAccessItem true
crudini --set --ini-options=nospace "$HOME/.config/keepassxc/keepassxc.ini" FdoSecrets Enabled true
crudini --set --ini-options=nospace "$HOME/.config/keepassxc/keepassxc.ini" FdoSecrets ShowNotification false

crudini --set --ini-options=nospace "$HOME/.config/keepassxc/keepassxc.ini" GUI CheckForUpdates false
crudini --set --ini-options=nospace "$HOME/.config/keepassxc/keepassxc.ini" GUI HideUsernames false
crudini --set --ini-options=nospace "$HOME/.config/keepassxc/keepassxc.ini" GUI MinimizeOnClose true
crudini --set --ini-options=nospace "$HOME/.config/keepassxc/keepassxc.ini" GUI MinimizeToTray true
crudini --set --ini-options=nospace "$HOME/.config/keepassxc/keepassxc.ini" GUI ShowTrayIcon true
crudini --set --ini-options=nospace "$HOME/.config/keepassxc/keepassxc.ini" GUI TrayIconAppearance monochrome-light

crudini --set --ini-options=nospace "$HOME/.config/keepassxc/keepassxc.ini" SSHAgent Enabled true

crudini --set --ini-options=nospace "$HOME/.config/keepassxc/keepassxc.ini" Security LockDatabaseIdle false
crudini --set --ini-options=nospace "$HOME/.config/keepassxc/keepassxc.ini" Security LockDatabaseScreenLock true

# Enable saving the last booted entry in GRUB.
set_option /etc/default/grub GRUB_DEFAULT saved
set_option /etc/default/grub GRUB_SAVEDEFAULT true

# Install and configure GRUB.
sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg

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

# Configure firewall.
sudo systemctl enable ufw.service
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on tailscale0
sudo ufw enable
sudo ufw logging off

#!/bin/env bash

set -euo pipefail

# Reference: https://github.com/Alexays/Waybar/discussions/1828#discussioncomment-10126615

# Adapted from /etc/sway/config.d/50-systemd-user.conf.
systemctl --user set-environment XDG_CURRENT_DESKTOP=sway
systemctl --user import-environment \
	DISPLAY \
	SWAYSOCK \
	WAYLAND_DISPLAY \
	XDG_CURRENT_DESKTOP

dbus-update-activation-environment --systemd \
	DISPLAY \
	SWAYSOCK \
	XDG_CURRENT_DESKTOP=sway \
	WAYLAND_DISPLAY

waybar &

# Wait for waybar to have started.
while ! dbus-send --session --dest=org.freedesktop.DBus --type=method_call --print-reply /org/freedesktop/DBus org.freedesktop.DBus.ListNames | grep org.kde.Status; do
	echo "waiting for tray..."
	sleep 0.2
done

# Gnome settings.
gnome_schema="org.gnome.desktop.interface"
gsettings set "$gnome_schema" gtk-theme 'oomox-tizix_dark'
gsettings set "$gnome_schema" icon-theme 'oomox-tizix_dark'
gsettings set "$gnome_schema" font-name 'Cantarell 11'

sway-fader \
	--app_id="foot:0.7:0.97" \
	--app_id="kitty:0.7:0.97" \
	--app_id="Alacritty:0.7:0.97" \
	--app_id="com.mitchellh.ghostty:0.7:0.97" \
	--class="XTerm:0.7:0.97" &
lxsession &
lxpolkit &
/usr/lib/geoclue-2.0/demos/agent &
gammastep-indicator &
nm-applet --indicator &
swaync &
thunar --daemon &
swaddle &
swayidle -w \
	timeout 600 'swaylock -f -c 000000' \
	timeout 1200 'swaymsg "output * dpms off"' \
	resume 'swaymsg "output * dpms on"' \
	before-sleep 'swaylock -f -c 000000' &

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

/usr/lib/mate-polkit/polkit-mate-authentication-agent-1 &
nm-applet --indicator &
swaync &
thunar --daemon &
bash ~/.pkgbuilds/systemd-audio-idle-inhibit/systemd-audio-idle-inhibit.sh &
swayidle -w \
	timeout 600 'lock' \
	timeout 1200 'swaymsg "output * dpms off"' \
	resume 'swaymsg "output * dpms on"' \
	before-sleep 'lock' &
gammastep-indicator -l "59.436962:24.753574" &

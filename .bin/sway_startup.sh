#!/usr/bin/env bash

set -euo pipefail

dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

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

export "$(/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh,gpg)"

sway-fader --app_id="foot:0.7:0.97" &
lxsession &
lxpolkit &
/usr/libexec/geoclue-2.0/demos/agent &
gammastep-indicator &
nm-applet --indicator &
swaync &
thunar --daemon &
sway-audio-idle-inhibit &
swayidle -w \
	timeout 600 'swaylock -f -c 000000' \
	timeout 1200 'swaymsg "output * dpms off"' \
	resume 'swaymsg "output * dpms on"' \
	before-sleep 'swaylock -f -c 000000' &

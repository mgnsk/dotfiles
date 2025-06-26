#!/bin/env bash

# This script runs Reaper on a headless X server through a client.

set -eu

function cleanup {
	xpra stop :100
}

trap cleanup EXIT

LOGFILE="$XDG_RUNTIME_DIR/reaper-$(date --iso-8601=seconds).log"

xpra desktop :100 --resize-display="1920x1000" --start-child=openbox --exit-with-children
xpra attach :100 &

(
	while ! grep -q "Starting audio shell" "$LOGFILE"; do
		echo "0"
	done
	echo "100"
) | zenity --title="Starting Reaper..." --progress --pulsate --no-cancel --auto-close --text="Please wait..." &

nix develop "${HOME}?submodules=1#audio" --show-trace \
	-s LIBGL_ALWAYS_SOFTWARE 1 \
	-s __GLX_VENDOR_LIBRARY_NAME mesa \
	-s VK_DRIVER_FILES /usr/share/vulkan/icd.d/lvp_icd.i686.json:/usr/share/vulkan/icd.d/lvp_icd.x86_64.json \
	-s DISPLAY :100 \
	--command bash -c 'reaper; wineserver -k || true' &>"$LOGFILE"

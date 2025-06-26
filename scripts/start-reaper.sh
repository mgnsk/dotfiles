#!/bin/env bash

# This script runs Reaper directly.

set -eu

LOGFILE="$XDG_RUNTIME_DIR/reaper-$(date --iso-8601=seconds).log"

(
	while ! grep -q "Starting audio shell" "$LOGFILE"; do
		echo "0"
	done
	echo "100"
) | zenity --title="Starting Reaper..." --progress --pulsate --no-cancel --auto-close --text="Please wait..." &

nix develop "${HOME}?submodules=1#audio" --show-trace \
	--command bash -c 'reaper; wineserver -k || true' &>"$LOGFILE"

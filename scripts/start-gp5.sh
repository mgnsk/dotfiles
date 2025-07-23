#!/bin/env bash

set -eu

function gp5 {
	fluidsynth --server --no-shell --audio-driver pulseaudio "$HOME/win-plugins/gm.sf2" &

	wine "$HOME/.wine/drive_c/Program Files (x86)/Guitar Pro 5/GP5.exe"

	killall fluidsynth
	wineserver -k || true
}
export -f gp5

LOGFILE="$XDG_RUNTIME_DIR/gp5-$$-$(date --iso-8601=seconds).log"

(
	start=$EPOCHSECONDS
	while ! grep -q "Starting audio shell" "$LOGFILE"; do
		echo "0"
		sleep 1
		if ((EPOCHSECONDS - start > 60)); then break; fi
	done
	echo "100"
) | zenity --title="Starting Guitar Pro 5..." --progress --pulsate --no-cancel --auto-close --text="Please wait..." &

nix develop "${HOME}?submodules=1#audio" --show-trace \
	--command unshare -nc bash -c 'gp5' &>"$LOGFILE"

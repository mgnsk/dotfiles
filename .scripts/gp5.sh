#!/bin/env bash

set -eu

function cleanup {
	killall fluidsynth
}

trap cleanup EXIT

fluidsynth --server --no-shell --audio-driver pulseaudio "$HOME/.win-plugins/gm.sf2" &

wine "$HOME/.wine/drive_c/Program Files (x86)/Guitar Pro 5/GP5.exe"

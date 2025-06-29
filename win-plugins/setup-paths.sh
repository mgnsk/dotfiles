#!/bin/env bash

set -eu

# Link plugins dir to Windows user home.
{
	src="$HOME/win-plugins"
	target="$HOME/.wine/drive_c/users/$USER/win-plugins"
	rm -rf "$target"
	ln -s "$src" "$target"
}

# Set up AppData.
{
	src="$HOME/win-plugins/AppData"
	target="$HOME/.wine/drive_c/users/$USER/AppData"
	rm -rf "$target"
	ln -s "$src" "$target"
}

# Set up VerbCore data.
{
	src="$HOME/win-plugins/Ugritone/VerbCore/VerbCore.cab"
	target="$HOME/.wine/drive_c/ProgramData/Ugritone/VerbCore/VerbCore.cab"

	if [ -f "$src" ]; then
		mkdir -p "$(dirname "$target")"
		ln -sf "$src" "$target"
	fi
}

# Set up yabridge paths.
{
	yabridgectl add "$HOME/win-plugins"
	yabridgectl sync --prune
	yabridgectl status
}

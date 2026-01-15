#!/bin/env bash

set -eu

# Set up wine prefix.
if [ ! -d "$WINEPREFIX" ]; then
	# Needed for some Windows VST plugins.
	winetricks -q dxvk

	# Needed for Guitar Pro 5.
	winetricks -q gdiplus
fi

# Link plugins dir to Windows user home.
{
	src="$HOME/.win-plugins"
	target="$WINEPREFIX/drive_c/users/$USER/.win-plugins"
	rm -rf "$target"
	ln -s "$src" "$target"
}

# Set up AppData.
{
	src="$HOME/.win-plugins/AppData"
	if [[ -d $src ]]; then
		target="$WINEPREFIX/drive_c/users/$USER/AppData"
		rm -rf "$target"
		ln -s "$src" "$target"
	fi
}

# Set up ProgramData.
{
	if [[ -d "$HOME/.win-plugins/ProgramData" ]]; then
		ln -sf "$HOME"/.win-plugins/ProgramData/* "$WINEPREFIX"/drive_c/ProgramData/
	fi
}

# Set up Program Files.
{
	if [[ -d "$HOME/.win-plugins/Program Files" ]]; then
		ln -sf "$HOME"/.win-plugins/Program\ Files/* "$WINEPREFIX"/drive_c/Program\ Files/
	fi

	if [[ -d "$HOME/.win-plugins/Program Files (x86)" ]]; then
		ln -sf "$HOME"/.win-plugins/Program\ Files\ \(x86\)/* "$WINEPREFIX"/drive_c/Program\ Files\ \(x86\)/
	fi
}

# Set up fonts.
{
	if [[ -d "$HOME/.win-plugins/windows/Fonts" ]]; then
		ln -sf "$HOME"/.win-plugins/windows/Fonts/* "$WINEPREFIX"/drive_c/windows/Fonts/
	fi
}

# Set up registry.
{
	if [[ -f "$HOME/.win-plugins/custom.reg" ]]; then
		wine regedit "$HOME/.win-plugins/custom.reg"
	fi
}

# Set up yabridge paths.
{
	if [[ -d "$HOME/.win-plugins/Plugins" ]]; then
		yabridgectl add "$HOME/.win-plugins/Plugins"
		yabridgectl sync --prune
		yabridgectl status
	fi
}

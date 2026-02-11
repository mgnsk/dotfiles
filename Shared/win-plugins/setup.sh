#!/bin/env bash

set -eu

# Set up wine prefix.
if [ ! -d "$WINEPREFIX" ]; then
	# Needed for some Windows VST plugins.
	winetricks -q dxvk

	# Needed for Guitar Pro 5.
	winetricks -q gdiplus
fi

WINPLUGINS="$HOME/Shared/win-plugins"

# Link plugins dir to Windows user home.
{
	target="$WINEPREFIX/drive_c/users/$USER/win-plugins"
	rm -rf "$target"
	ln -s "$WINPLUGINS" "$target"
}

# Set up AppData.
{
	src="$WINPLUGINS/AppData"
	if [[ -d $src ]]; then
		target="$WINEPREFIX/drive_c/users/$USER/AppData"
		rm -rf "$target"
		ln -s "$src" "$target"
	fi
}

# Set up Documents.
{
	src="$WINPLUGINS/Documents"
	if [[ -d $src ]]; then
		target="$WINEPREFIX/drive_c/users/$USER/Documents"
		rm -rf "$target"
		ln -s "$src" "$target"
	fi
}

# Set up ProgramData.
{
	if [[ -d "$WINPLUGINS/ProgramData" ]]; then
		ln -sf "$WINPLUGINS"/ProgramData/* "$WINEPREFIX"/drive_c/ProgramData/
	fi
}

# Set up Program Files.
{
	if [[ -d "$WINPLUGINS/Program Files" ]]; then
		ln -sf "$WINPLUGINS"/Program\ Files/* "$WINEPREFIX"/drive_c/Program\ Files/
	fi

	if [[ -d "$WINPLUGINS/Program Files (x86)" ]]; then
		ln -sf "$WINPLUGINS"/Program\ Files\ \(x86\)/* "$WINEPREFIX"/drive_c/Program\ Files\ \(x86\)/
	fi
}

# Set up fonts.
{
	if [[ -d "$WINPLUGINS/windows/Fonts" ]]; then
		ln -sf "$WINPLUGINS"/windows/Fonts/* "$WINEPREFIX"/drive_c/windows/Fonts/
	fi
}

# Set up registry.
{
	if [[ -f "$WINPLUGINS/custom.reg" ]]; then
		wine regedit "$WINPLUGINS/custom.reg"
	fi
}

# Set up yabridge paths.
{
	if [[ -d "$WINPLUGINS/Plugins" ]]; then
		yabridgectl add "$WINPLUGINS/Plugins"
		yabridgectl sync --prune
		yabridgectl status
	fi
}

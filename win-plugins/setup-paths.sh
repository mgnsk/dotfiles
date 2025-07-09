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

# Set up ProgramData.
{
	ln -sf "$HOME"/win-plugins/ProgramData/* "$HOME"/.wine/drive_c/ProgramData/
}

# Set up Program Files.
{
	ln -sf "$HOME"/win-plugins/Program\ Files/* "$HOME"/.wine/drive_c/Program\ Files/
	ln -sf "$HOME"/win-plugins/Program\ Files\ \(x86\)/* "$HOME"/.wine/drive_c/Program\ Files\ \(x86\)/
}

# Set up fonts.
{
	ln -sf "$HOME"/win-plugins/windows/Fonts/* "$HOME"/.wine/drive_c/windows/Fonts/
}

# Set up registry.
{
	wine regedit "$HOME/win-plugins/custom.reg"
}

# Set up yabridge paths.
{
	yabridgectl add "$HOME/win-plugins/Plugins"
	yabridgectl sync --prune
	yabridgectl status
}

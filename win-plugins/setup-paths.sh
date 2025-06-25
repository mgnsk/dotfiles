#!/bin/env bash

set -eu

# Link plugins dir to Windows user home.
{
	ln -sf "$HOME/win-plugins" "$HOME/.wine/drive_c/users/$USER/win-plugins"
}

# Set up Ampenstein data paths.
{
	target="/home/${USER}/.wine/drive_c/users/${USER}/AppData/Roaming/Ugritone/Ampenstein/config.xml"
	mkdir -p "$(dirname "$target")"

	cat <<'EOF' | tee "$target" >/dev/null
<?xml version="1.0" encoding="UTF-8"?>

<root pluginDataPath="Z:\home\_USER_\win-plugins\Ugritone\Ampenstein\Processors"
	  IRPath="Z:\home\_USER_\win-plugins\Ugritone\Ampenstein\Impulse Responses"
	  flipChannels="0" temporarySaveAmpStatesForEachSlot="1" UserPresetsPath="Z:\home\_USER_\win-plugins\Ugritone\Ampenstein\User Presets"
	  BGImagePath=""/>
EOF

	# TODO: howto expand env vars in heredoc?
	sed -i "s/_USER_/${USER}/" "$target"
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

# Set up VerbCore data paths.
{
	target="/home/${USER}/.wine/drive_c/users/${USER}/AppData/Roaming/Ugritone/VerbCore/config.cfg"
	mkdir -p "$(dirname "$target")"

	cat <<'EOF' | tee "$target" >/dev/null
<?xml version="1.0" encoding="UTF-8"?>

<root userDataPath="Z:\home\_USER_\win-plugins\Ugritone\VerbCore"/>
EOF

	# TODO: howto expand env vars in heredoc?
	sed -i "s/_USER_/${USER}/" "$target"
}

# Set up yabridge paths.
{
	yabridgectl add "$HOME/win-plugins"
	yabridgectl sync --prune
	yabridgectl status
}

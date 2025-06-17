#!/bin/env sh

set -eu

ampensteinCfg="/home/${USER}/.wine/drive_c/users/${USER}/AppData/Roaming/Ugritone/Ampenstein/config.xml"

# Set up Ampenstein data paths.
cat <<'EOF' | tee "$ampensteinCfg" >/dev/null
<?xml version="1.0" encoding="UTF-8"?>

<root pluginDataPath="Z:\home\_USER_\win-plugins\Ugritone\Ampenstein\Processors"
	  IRPath="Z:\home\_USER_\win-plugins\Ugritone\Ampenstein\Impulse Responses"
	  flipChannels="0" temporarySaveAmpStatesForEachSlot="1" UserPresetsPath="Z:\home\_USER_\win-plugins\Ugritone\Ampenstein\User Presets"
	  BGImagePath=""/>
EOF

# TODO: howto expand env vars in heredoc?
sed -i "s/_USER_/${USER}/" "$ampensteinCfg"

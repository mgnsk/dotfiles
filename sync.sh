#!/bin/env bash

set -eu

declare -A mappings=(
	["$HOME/Shared"]="gdrive:/Shared"
	["$HOME/Studio"]="gdrive:/Studio"
	["$HOME/Documents"]="gdrive:/Documents"
	["$HOME/.win-plugins"]="gdrive:/Audio/.win-plugins"
	["$HOME/.vst3"]="gdrive:/Audio/.vst3"
)

for host_dir in "${!mappings[@]}"; do
	remote_dir="${mappings[$host_dir]}"

	echo "### Syncing $host_dir"

	rclone bisync \
		--progress \
		--copy-links \
		--resilient \
		--recover \
		--max-lock 2m \
		--conflict-resolve newer \
		--resync-mode newer \
		--exclude "yabridge/**" \
		"$host_dir" \
		"$remote_dir"
done

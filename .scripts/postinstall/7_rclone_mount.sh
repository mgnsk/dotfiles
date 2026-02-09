#!/bin/env bash

set -eu

# TODO: before sleep, stop the services
# when resuming, start the services again
# to prevent broken mounts

for remote in $(rclone listremotes); do
	remote="${remote::-1}"
	dir="/mnt/$(id -un)/$remote"

	echo "Unmounting $remote mount at $dir if mounted"
	systemctl --user stop "rclone@$remote"

	sudo mkdir -p "$dir"
	sudo chown "$(id -un):$(id -gn)" "$dir"

	echo "Enabling $remote mount at $dir"
	systemctl --user enable --now "rclone@$remote"
done

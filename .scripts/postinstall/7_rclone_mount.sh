#!/bin/env bash

set -eu

for remote in $(rclone listremotes); do
	remote="${remote::-1}"
	dir="/mnt/$(id -un)/$remote"
	sudo mkdir -p "$dir"
	sudo chown "$(id -un):$(id -gn)" "$dir"
	echo "Unmounting $remote mount at $dir if mounted"
	systemctl --user stop "rclone@$remote"
	echo "Enabling $remote mount at $dir"
	systemctl --user enable --now "rclone@$remote"
done

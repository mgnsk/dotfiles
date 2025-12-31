#!/bin/env bash

set -eu

for remote in $(rclone listremotes); do
	remote="${remote::-1}"
	dir="$HOME/$remote"
	mkdir -p "$dir"
	echo "Unmounting $remote mount at $dir if mounted"
	systemctl --user stop "rclone@$remote"
	echo "Enabling $remote mount at $dir"
	systemctl --user enable --now "rclone@$remote"
done

#!/bin/env bash

set -eu

rclone bisync \
	--progress \
	--resilient \
	--recover \
	--max-lock 2m \
	--conflict-resolve newer \
	--resync-mode newer \
	"$HOME/Shared" \
	"gdrive:/Shared"

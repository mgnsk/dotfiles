#!/bin/env bash

set -eu

rclone copy \
	--progress \
	--exclude "yabridge/**" \
	"$HOME/Shared" \
	"cloud:Shared"

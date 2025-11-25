#!/bin/env bash

set -eu

rclone bisync --progress -v . "gdrive:/Audio/.vst3" --exclude "yabridge/**"

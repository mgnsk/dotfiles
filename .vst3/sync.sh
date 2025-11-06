#!/bin/env bash

set -eu

rclone sync -v . "gdrive:/Audio/.vst3" --exclude "yabridge/**"

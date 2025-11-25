#!/bin/env bash

set -eu

rclone bisync --progress -v . "gdrive:/Audio/.win-plugins"

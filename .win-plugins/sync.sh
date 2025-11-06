#!/bin/env bash

set -eu

rclone sync -v . "gdrive:/Audio/.win-plugins"

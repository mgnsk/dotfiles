#!/bin/env bash

set -eu

rclone sync -v ~/*.kdbx "gdrive:/"

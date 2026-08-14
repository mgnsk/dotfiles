#!/bin/env bash

set -euo pipefail

waybar &

wayvnc -o HEADLESS-1 -Linfo 0.0.0.0 5900 &

#!/bin/env bash

set -euo pipefail

zenity --info --text="$(grim -g "$(slurp -p)" -t ppm - | magick - -format "%[pixel:p{0,0}]" txt:-)"

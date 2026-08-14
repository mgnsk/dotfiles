#!/bin/env bash

set -euo pipefail

# Run a second, fully independent sway compositor with a virtual (headless)
# output for remote access via wayvnc. Because it is a separate process with
# its own socket/display, locking the main desktop's sway instance has no
# effect on this one.
#
# WLR_BACKENDS=headless forces wlroots to skip DRM/libinput entirely, so this
# instance never touches the real seat and doesn't fight the main sway
# instance for the display or input devices. wayvnc feeds input back in via
# the virtual-keyboard/virtual-pointer protocols instead.
export WLR_BACKENDS=headless
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export SWAYSOCK="$XDG_RUNTIME_DIR/sway-vnc.sock"

exec sway -c "$HOME/.config/sway/config-vnc"

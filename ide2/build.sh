#!/usr/bin/env bash

set -euo pipefail

function get-build-context {
	cd "$HOME" && git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" ls-files --recurse-submodules | tar Tc -
}

rm -rf dotfiles
mkdir -p dotfiles
get-build-context | tar Cx dotfiles

docker build \
	-t ghcr.io/mgnsk/ide2:edge \
	.

# --build-arg uid=1000 \
# --build-arg gid=1000 \
# --build-arg user=ide \
# --build-arg group=ide \

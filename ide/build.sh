#!/usr/bin/env bash

set -euo pipefail

function get-build-context {
	cd "$HOME" && git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" ls-files | tar Tc -
}

rm -rf dotfiles
mkdir -p dotfiles
get-build-context | tar Cx dotfiles

# Note: setting ulimit fixes the fakeroot slowness issue.
# https://github.com/greyltc-org/docker-archlinux-aur/issues/7#issuecomment-1516028357
docker build \
	--ulimit nofile=1024:10240 \
	--build-arg uid=1000 \
	--build-arg gid=1000 \
	--build-arg user=ide \
	--build-arg group=ide \
	-t ghcr.io/mgnsk/ide:edge \
	.

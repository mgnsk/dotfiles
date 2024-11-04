#!/usr/bin/env bash

set -euo pipefail

declare -a packages=(
	"hadolint-bin"
	"shellcheck-bin"
	"lscolors-git"
	"wl-kbptr"
)

# Disable makepkg compression.
export PKGEXT=".pkg.tar"

for p in "${packages[@]}"; do
	mkdir -p "$HOME/.cache/aur/$p"
	cd "$HOME/.cache/aur/$p"

	if test -d ./.git; then
		git pull
	else
		git clone "https://aur.archlinux.org/$p.git" .
	fi

	makepkg --force --noconfirm --needed --syncdeps --clean --cleanbuild --rmdeps --install
done

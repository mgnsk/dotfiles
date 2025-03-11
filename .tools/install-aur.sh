#!/usr/bin/env bash

set -euo pipefail

# Disable makepkg compression.
export PKGEXT=".pkg.tar"

for dir in "$HOME"/.tools/aur/*; do
	cd "$dir"
	makepkg --force --noconfirm --needed --syncdeps --clean --cleanbuild --rmdeps --install
done

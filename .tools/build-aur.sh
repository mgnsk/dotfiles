#!/usr/bin/env bash

set -euo pipefail

declare -a packages=(
	"fish-fzf"
	"hadolint-bin"
	"shellcheck-bin"
	"lscolors-git"
	"phpactor"
	"phpstan-bin"
)

# gpg: key 51C67305FFC2E5C0: public key "PHPStan Bot <ondrej+phpstanbot@mirtes.cz>"
gpg --keyserver keys.openpgp.org --recv-keys CA7C2C7A30C8E8E1274A847651C67305FFC2E5C0

for p in "${packages[@]}"; do
	mkdir -p "$HOME/.cache/aur/$p"
	cd "$HOME/.cache/aur/$p"

	if test -d ./.git; then
		git pull
	else
		git clone "https://aur.archlinux.org/$p.git" .
	fi

	makepkg --force --noconfirm --needed --syncdeps --clean --cleanbuild --rmdeps
done

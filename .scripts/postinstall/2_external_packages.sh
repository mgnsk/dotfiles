#!/bin/env bash

set -eu

# Set up rust.
rustup update
rustup default stable
rustup component add rust-analyzer

# Set up PHP.
sudo sed -i -e 's/;extension=iconv/extension=iconv/g' /etc/php/php.ini

# Install JS packages.
(
	cd "$HOME/.npm-packages"
	npm ci
)

# Install PKGBUILDs.
pkgbuilds=(
	gh-tpl-bin
	jsfx-lint-bin
	tusk-bin
	yay-bin
)

for pkg in "${pkgbuilds[@]}"; do
	makepkg -D "$HOME/.pkgbuilds/$pkg" -si --needed
done

# Install AUR packages.
packages=(
	1password
	1password-cli
	brave-bin
	downgrade
	gojq-bin
	go-jsonnet
	hadolint-bin
	helm-ls-bin
	jsonnet-language-server
	nil-git
	nixfmt
	obmenu-generator
	phpactor-bin
	phpstan-bin
	raysession
	shellcheck-bin
	shntool
	snap-pac-grub
	wdisplays
	qdigidoc4
	web-eid
)

yay -S "${packages[@]}"

sudo systemctl enable pcscd.socket

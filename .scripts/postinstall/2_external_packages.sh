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

# Install Go packages.
(
	cd "$HOME/.go-packages"
	export GOBIN="$HOME/.go-packages/bin"
	go install tool
)

# 1password signing key.
gpg --keyserver keyserver.ubuntu.com --recv-keys 3FEF9748469ADBE15DA7CA80AC2D62742012EA22

# phpstan-bin signing key.
gpg --keyserver keys.openpgp.org --recv-keys 51C67305FFC2E5C0

# TODO pkgbuilds
# jsfx-lint

# Install AUR packages.
packages=(
	1password
	1password-cli
	brave-bin

	python-iniparse
	crudini

	downgrade
	gojq-bin
	go-jsonnet
	hadolint-bin
	helm-ls-bin
	jsfx-lint
	jsonnet-language-server
	nil-git
	nixfmt

	perl-linux-desktopfiles
	obmenu-generator

	phpactor-bin
	phpstan-bin
	raysession
	rclone-browser
	shellcheck-bin
	snap-pac-grub
	wdisplays
	wine-tkg-staging-wow64-bin
	yay-bin
)

for pkg in "${packages[@]}"; do
	makepkg -D "$HOME/.pkgbuilds/$pkg" -si --needed
done

# Install support for Estonian ID card.
packages=(
	libdigidocpp
	qdigidoc4
	web-eid
)

# Estonian ID card signing key.
gpg --keyserver keyserver.ubuntu.com --recv-keys 90C0B5E75C3B195D

for pkg in "${packages[@]}"; do
	makepkg -D "$HOME/.pkgbuilds/$pkg" -si --needed
done

sudo systemctl enable pcscd.socket

# Checkout pkgbuild repos again. Needed for -git packages.
for d in ~/.pkgbuilds/*/; do
	git -C "$d" checkout . || true
done

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

# 1password signing key.
gpg --keyserver keyserver.ubuntu.com --recv-keys 3FEF9748469ADBE15DA7CA80AC2D62742012EA22

# phpstan-bin signing key.
gpg --keyserver keys.openpgp.org --recv-keys 51C67305FFC2E5C0

# Install AUR packages.
packages=(
	1password
	1password-cli
	brave-bin

	python-iniparse
	crudini

	downgrade
	gh-tpl-bin
	gojq-bin
	go-jsonnet
	hadolint-bin
	helm-ls-bin
	jsfx-lint-bin
	jsonnet-language-server
	nil-git
	nixfmt

	perl-linux-desktopfiles
	obmenu-generator

	phpactor-bin
	phpstan-bin
	raysession
	shellcheck-bin
	shntool
	snap-pac-grub
	tusk-bin
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

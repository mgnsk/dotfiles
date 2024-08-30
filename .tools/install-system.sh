#!/usr/bin/env bash

set -euo pipefail

sudo pacman -Syy

sudo pacman -S --noconfirm --needed archlinux-keyring

sudo pacman -S --noconfirm --needed \
	git \
	git-delta \
	unzip \
	wget \
	tmux \
	fish \
	tree \
	ripgrep \
	fd \
	bat \
	fzf \
	glow \
	parallel \
	moreutils \
	earlyoom \
	tidy \
	npm \
	go \
	gopls \
	go-tools \
	revive \
	shfmt \
	github-cli \
	buf \
	yamllint \
	brotli \
	direnv \
	luarocks \
	lua-language-server \
	luacheck \
	stylua \
	rtmidi \
	php \
	php-sqlite \
	composer \
	rustup \
	man \
	python-pipx \
	neovim \
	clang

declare -a packages=(
	"fish-fzf"
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

# Generate locales.
echo "en_US.UTF-8 UTF-8" | sudo tee /etc/locale.gen
sudo locale-gen
echo "LANG=en_US.UTF-8" | sudo tee /etc/locale.conf

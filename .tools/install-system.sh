#!/usr/bin/env bash

set -euo pipefail

sudo pacman -Syy

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
	buf \
	yamllint \
	shfmt \
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
	github-cli

declare -a packages=(
	"fish-fzf"
	"hadolint-bin"
	"shellcheck-bin"
	"lscolors-git"
)

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

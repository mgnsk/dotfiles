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

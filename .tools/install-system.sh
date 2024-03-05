#!/usr/bin/env bash

set -euo pipefail

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
	skim \
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
	neovim

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
	prettier \
	typescript-language-server \
	vscode-html-languageserver \
	vscode-css-languageserver \
	svelte-language-server \
	npm \
	npm-check-updates \
	eslint \
	go \
	gopls \
	go-tools \
	buf \
	yamllint \
	shfmt \
	bash-language-server \
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

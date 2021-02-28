#!/bin/bash

set -e

. ~/.env

function install_paru {
	url="https://aur.archlinux.org/paru-bin.git"
	tmp="$HOME/.cache/paru-bin"

	if ! git clone "${url}" "${tmp}" 2>/dev/null && [ -d "${tmp}" ]; then
		echo "paru already installed"
		return 0
	fi

	cd "$tmp"
	makepkg -si --noconfirm
	cd
	rm -rf "$tmp"
}

function pkgbuild {
	paru -S --noconfirm --needed \
		fish-fzf-git \
		direnv \
		hadolint-bin \
		neovim-git
}

function ensure_dirs {
	mkdir -p \
		~/.local/share/direnv \
		~/.tmux/resurrect \
		~/.npm-global \
		~/.local/bin \
		~/.local/lib
}

install_paru
pkgbuild
ensure_dirs

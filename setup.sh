#!/bin/bash

set -e

. ~/.env

function install_paru {
	tmp=~/.cache/paru-bin
	git clone https://aur.archlinux.org/paru-bin.git $tmp &&
		cd $tmp &&
		makepkg -si --noconfirm &&
		cd &&
		rm -rf $tmp
}

function pkgbuild {
	paru -S --noconfirm --needed \
		direnv \
		hadolint-bin \
		neovim-git
}

function do_install {
	cd "$(dirname "$1")"
	echo "### Installing: $1"
	bash "$1"
}

export -f do_install

function install_tools {
	find ~/.tools/*/install.sh -maxdepth 1 -print0 | parallel -k -u --halt-on-error 2 -0 -j"$(nproc)" do_install {}
}

function cleanup {
	paru -c --noconfirm
	yes | paru -Scc
	go clean -modcache
	rm -rf ~/.cache
	mkdir ~/.cache
}

function ensure_dirs {
	mkdir -p \
		~/.cache \
		~/.local/share/direnv \
		~/.tmux/resurrect \
		~/.npm-global \
		~/.local/bin \
		~/.local/lib
}

install_paru
pkgbuild
install_tools
cleanup
ensure_dirs

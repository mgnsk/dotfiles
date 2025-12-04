#!/bin/env bash

set -eu

# Set up dotfiles.
if [[ ! -d "$HOME/.git" ]]; then
	git clone --recurse-submodules --separate-git-dir="$HOME/.git" https://github.com/mgnsk/dotfiles.git "$HOME/dotfiles-tmp"
	git config status.showUntrackedFiles no
	git reset --hard --recurse-submodules origin/master
	rm -rf "$HOME/dotfiles-tmp"
fi

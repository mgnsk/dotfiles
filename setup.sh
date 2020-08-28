#!/bin/bash

set -euo pipefail

function setup_tmux() {
	tpm_dir=~/.tmux/plugins/tpm
	if [ -d $tpm_dir ]; then
		cd $tpm_dir && git pull
	else
		git clone --depth 1 https://github.com/tmux-plugins/tpm $tpm_dir
	fi

	export TMUX_PLUGIN_MANAGER_PATH=$HOME/.tmux/plugins/tpm

	~/.tmux/plugins/tpm/bin/install_plugins
}

function setup_vim() {
	curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

	if test ! -f ~/.vim/init.vim; then
		ln -s $HOME/.vimrc $HOME/.vim/init.vim
	fi

	if test ! -d ~/.config/nvim; then
		ln -s $HOME/.vim $HOME/.config/nvim
	fi

	nvim --headless -u ~/.vim/plugins.vim -S ~/.vim/plugin.lock -c 'qa'
	nvim --headless -u ~/.vim/plugins.vim -c 'call gopher#system#setup()' -c 'qa'

	go clean -modcache

	cd ~/.config/coc/extensions
	yarn

	pip install --no-cache-dir neovim-remote
}

function setup_rust() {
	#rustup default stable
	rustup component add rls rust-analysis rust-src
}

function setup_fzf() {
	fzf_dir=~/.fzf
	if [ -d $fzf_dir ]; then
		cd $fzf_dir && git pull
	else
		git clone --depth 1 https://github.com/junegunn/fzf.git $fzf_dir
	fi
	~/.fzf/install --all
}

# TODO setup tools module
function setup_gotools() {
	go get mvdan.cc/gofumpt/gofumports
}

setup_tmux
setup_vim
setup_rust
setup_fzf
setup_gotools

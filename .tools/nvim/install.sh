#!/bin/bash

set -e

if test ! -f ~/.vim/autoload/plug.vim; then
	curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

if test ! -f ~/.vim/init.vim; then
	ln -s $HOME/.vimrc $HOME/.vim/init.vim
fi

if test ! -d ~/.config/nvim; then
	ln -s $HOME/.vim $HOME/.config/nvim
fi

nvim --headless -u ~/.vim/plugins.vim -S ~/.vim/plugin.lock -c 'qa'

cd ~/.config/coc/extensions
yarn

pip3 install --no-cache-dir neovim-remote

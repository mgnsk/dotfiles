#!/bin/bash

set -e

NEOVIM_COMMIT=71d4f5851f068eeb432af34850dddda8cc1c71e3

src_dir=~/neovim_src
if [ -d $src_dir ]; then
	cd $src_dir
	git checkout master
	git pull
else
	git clone https://github.com/neovim/neovim.git $src_dir
fi

cd $src_dir
git checkout $NEOVIM_COMMIT

make CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$HOME/.neovim -DCMAKE_BUILD_TYPE=RelWithDebInfo"
make install
make distclean

nvim --version

if test ! -f ~/.vim/autoload/plug.vim; then
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

if test ! -f ~/.vim/init.vim; then
    ln -s "$HOME/.vimrc" "$HOME/.vim/init.vim"
fi

if test ! -d ~/.config/nvim; then
    ln -s "$HOME/.vim" "$HOME/.config/nvim"
fi

nvim --headless -u ~/.vim/plugins.vim -S ~/.vim/plugin.lock -c 'qa'
nvim --headless -u ~/.vim/plugins.vim -c 'TSInstallSync all' -c 'qa'

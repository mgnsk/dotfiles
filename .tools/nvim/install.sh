#!/bin/bash

set -e

neovim_commit=31787a91dcb1dc4b346129d22d0f44eb17a1f392

wget https://github.com/neovim/neovim/archive/${neovim_commit}.zip
unzip -q ${neovim_commit}.zip
rm ${neovim_commit}.zip
cd neovim-${neovim_commit}
make CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$HOME/.neovim -DCMAKE_BUILD_TYPE=Release"
make install
cd ..
rm -rf neovim-${neovim_commit}

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

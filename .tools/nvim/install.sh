#!/bin/bash

set -e

neovim_commit=08c0eef52a31f70190fd4aa0ea8d54c0a169b284

wget https://github.com/neovim/neovim/archive/${neovim_commit}.zip
unzip -q ${neovim_commit}.zip
rm ${neovim_commit}.zip
cd neovim-${neovim_commit}
make CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$HOME/.neovim -DCMAKE_BUILD_TYPE=Release"
make install
cd ..
rm -rf neovim-${neovim_commit}

nvim --version
nvim --headless -c 'PaqInstall' -c 'qa'
nvim --headless -c 'TSInstallSync all' -c 'qa'

##nvim --headless -u ~/.vim/plugins.vim -S ~/.vim/plugin.lock -c 'qa'
##nvim --headless -u ~/.vim/plugins.vim -c 'TSInstallSync all' -c 'qa'

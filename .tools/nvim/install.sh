#!/bin/bash

set -e

neovim_commit=7afd4526f2ee018ef611f91bfe1b0cb8ed2fc4c6

wget https://github.com/neovim/neovim/archive/${neovim_commit}.zip
unzip -q ${neovim_commit}.zip
rm ${neovim_commit}.zip
cd neovim-${neovim_commit}
make CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$HOME/.neovim -DCMAKE_BUILD_TYPE=Release"
make install
cd ..
rm -rf neovim-${neovim_commit}

nvim --version
nvim --headless -u ~/.config/nvim/lua/plugins.lua -c 'PkgInstall' -c 'qa'
nvim --headless -u ~/.config/nvim/lua/plugins.lua -c 'TSInstallSync all' -c 'qa'

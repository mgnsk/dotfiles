#!/bin/bash

set -e

neovim_commit=82100a6bdb42cec30060d6c991ab78fd2331fa31

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

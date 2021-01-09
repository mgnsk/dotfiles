#!/bin/bash

set -e

neovim_commit=fe1ebea33914df137fdded98872fe38fa8470384

wget https://github.com/neovim/neovim/archive/${neovim_commit}.zip
unzip -q ${neovim_commit}.zip
rm ${neovim_commit}.zip
cd neovim-${neovim_commit}
make CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$HOME/.neovim -DCMAKE_BUILD_TYPE=RelWithDebInfo"
make install
cd ..
rm -rf neovim-${neovim_commit}

nvim --version
nvim --headless -u ~/.config/nvim/lua/plugins.lua -c 'PkgInstall' -c 'qa'
nvim --headless -c 'TSInstallSync all' -c 'qa'

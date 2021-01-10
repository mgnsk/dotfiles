#!/bin/bash

set -e

nvim --headless -u ~/.config/nvim/lua/plugins.lua -c 'PkgInstall' -c 'qa'
nvim --headless -c 'TSInstallSync all' -c 'qa'
rm -rf ~/.local/share/nvim/*.tar.gz

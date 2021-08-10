#!/bin/bash

set -e

git clone --recurse-submodules https://github.com/tlaplus-community/tree-sitter-tlaplus.git ~/.tools/nvim/tree-sitter-tlaplus
cd ~/.tools/nvim/tree-sitter-tlaplus
npm install

nvim --headless -u ~/.config/nvim/lua/plugins.lua -c 'PkgInstall' -c 'qa'

function ts_install {
	nvim --headless -c "TSInstallSync $1" -c "qa"
}

ts_install javascript
ts_install c
ts_install cpp
ts_install rust
ts_install lua
ts_install go
ts_install bash
ts_install php
ts_install html
ts_install json
ts_install css
ts_install typescript
ts_install toml
ts_install elm
ts_install yaml
ts_install regex
ts_install tlaplus

rm -rf ~/.local/share/nvim/*.tar.gz

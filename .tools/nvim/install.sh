#!/usr/bin/env bash

set -e

function pkg_install {
	pluginDir=~/.local/share/nvim/site/pack/pkg/start
	mkdir -p $pluginDir
	cd $pluginDir

	name="$(echo "$1" | cut -d'/' -f2)"

	if [ -d "$pluginDir/$name" ]; then
		cd "$pluginDir/$name"
		git pull
	else
		git clone "https://github.com/$1.git" "$name"
	fi
}

pkg_install "nvim-treesitter/nvim-treesitter"
pkg_install "nvim-treesitter/playground"
pkg_install "rktjmp/lush.nvim"
pkg_install "norcalli/nvim-colorizer.lua"

pkg_install "b3nj5m1n/kommentary"
pkg_install "junegunn/fzf"
pkg_install "junegunn/fzf.vim"
pkg_install "airblade/vim-gitgutter"
pkg_install "sebdah/vim-delve"
pkg_install "neomake/neomake"
pkg_install "tpope/vim-fugitive"
pkg_install "svermeulen/vimpeccable"

pkg_install "nvim-lua/lsp_extensions.nvim"
pkg_install "neovim/nvim-lspconfig"
pkg_install "ray-x/lsp_signature.nvim"
pkg_install "gfanto/fzf-lsp.nvim"
pkg_install "liuchengxu/vista.vim"
pkg_install "RRethy/vim-illuminate"

pkg_install "hrsh7th/nvim-cmp"
pkg_install "hrsh7th/cmp-buffer"
pkg_install "hrsh7th/cmp-nvim-lsp"
pkg_install "hrsh7th/cmp-nvim-lua"
pkg_install "hrsh7th/cmp-path"

pkg_install "mhartington/formatter.nvim"
pkg_install "rbtnn/vim-vimscript_indentexpr"
pkg_install "Townk/vim-autoclose"

function ts_install {
	nvim -u NORC --headless -c "TSUpdateSync $1" -c "qa"
	printf "\n"
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
ts_install tsx
ts_install svelte
ts_install vue
ts_install toml
ts_install elm
ts_install yaml
ts_install regex
ts_install tlaplus
ts_install beancount
ts_install ledger
ts_install comment
ts_install make
ts_install regex
ts_install vim

rm -rf ~/.local/share/nvim/*.tar.gz

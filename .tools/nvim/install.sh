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
pkg_install "ibhagwan/fzf-lua"
pkg_install "airblade/vim-gitgutter"
pkg_install "neomake/neomake"
pkg_install "tpope/vim-fugitive"
pkg_install "AckslD/nvim-neoclip.lua"

pkg_install "neovim/nvim-lspconfig"
pkg_install "ray-x/lsp_signature.nvim"
pkg_install "liuchengxu/vista.vim"
pkg_install "RRethy/vim-illuminate"
pkg_install "simrat39/rust-tools.nvim"

pkg_install "hrsh7th/nvim-cmp"
pkg_install "hrsh7th/cmp-buffer"
pkg_install "hrsh7th/cmp-nvim-lsp"
pkg_install "hrsh7th/cmp-nvim-lua"
pkg_install "hrsh7th/cmp-path"

pkg_install "Townk/vim-autoclose" # TODO: check out alternatives

pkg_install "ellisonleao/glow.nvim"

nvim -u NORC --headless -c "TSInstallSync all" -c "qa"
nvim -u NORC --headless -c "TSUpdateSync all" -c "qa"

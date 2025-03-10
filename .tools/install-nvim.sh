#!/usr/bin/env bash

set -euo pipefail

nvim --headless -u NORC \
	-c 'lua if not require("lazy_setup") then os.exit(1) end' \
	-c 'lua local ok, result = pcall(vim.cmd, "Lazy! build nvim-treesitter"); if not ok then print(result); os.exit(1) end' \
	-c 'lua os.exit(0)'

nvim --headless -u NORC \
	-c 'lua if not require("lazy_setup") then os.exit(1) end' \
	-c 'lua local ok, result = pcall(vim.cmd, "Lazy! build tree-sitter-balafon"); if not ok then print(result); os.exit(1) end' \
	-c 'lua os.exit(0)'

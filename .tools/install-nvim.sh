#!/usr/bin/env bash

set -euo pipefail

nvim --headless -u NORC \
	-c 'lua if not require("lazy_setup") then os.exit(1) end' \
	-c 'lua local ok, result = pcall(vim.cmd, "Lazy! restore"); if not ok then print(result); os.exit(1) end' \
	-c 'lua os.exit(0)'

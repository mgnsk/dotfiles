#!/bin/bash

set -e

nvim --headless -c "TSUninstall all" -c "qa"

rm -rf ~/.local/share/nvim/site/pack/pkg/start

rm -rf ~/.tools/nvim/tree-sitter-tlaplus

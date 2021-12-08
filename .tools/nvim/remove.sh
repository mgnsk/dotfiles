#!/bin/bash

set -e

nvim --headless -c "TSUninstall all" -c "qa" || true

rm -rf ~/.local/share/nvim/site/pack/pkg/start

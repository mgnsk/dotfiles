#!/usr/bin/env bash

set -e

nvim --headless "+Lazy! sync" +qa
nvim --headless -c "TSInstallSync all" -c "qa"
nvim --headless -c "TSUpdateSync all" -c "qa"

#!/bin/bash

set -e

pip3 install --no-cache-dir \
    neovim-remote \
    yamllint \
    ansible-lint \
    vim-vint \
    proselint

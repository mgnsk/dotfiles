#!/usr/bin/env bash

set -euo pipefail

rustup update
rustup default stable
rustup component add rustfmt rust-src clippy rust-analyzer

mkdir -p ~/.config/fish/completions
rustup completions fish >~/.config/fish/completions/rustup.fish

#!/bin/bash

set -e

if ! command -v rustup &>/dev/null; then
    echo "### Skipping rust tools"
    exit 0
fi

echo "### Installing rust tools"
rustup component add rustfmt rls rust-analysis rust-src clippy
rm -rf ~/.cargo/registry

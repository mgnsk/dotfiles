#!/bin/bash

set -euo pipefail

echo "### Installing rust tools"

# install toolchain
curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly -y
rustup default nightly
rustup component add rustfmt rust-src clippy rust-analyzer-preview

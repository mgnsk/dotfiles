#!/bin/bash

set -euo pipefail

echo "### Installing rust tools"

rustup default stable
rustc -V
rustup component add rustfmt rls rust-analysis rust-src clippy

rm -rf ~/.cargo/registry

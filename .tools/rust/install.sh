#!/bin/bash

set -euo pipefail

echo "### Installing rust tools"

rustup default nightly
rustc -V
rustup component add rustfmt rust-src clippy rust-analyzer-preview

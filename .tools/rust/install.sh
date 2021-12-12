#!/bin/bash

set -euo pipefail

echo "### Installing rust tools"

rustup default nightly
rustup component add rustfmt rust-src clippy rust-analyzer-preview

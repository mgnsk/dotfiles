#!/usr/bin/env bash

set -euo pipefail

rustup update
rustup default stable
rustup component add rustfmt rust-src clippy rust-analyzer

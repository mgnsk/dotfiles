#!/usr/bin/env bash

set -euo pipefail

rustup default nightly
rustup component add rustfmt rust-src clippy rust-analyzer-preview

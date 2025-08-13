#!/bin/env bash

set -eu

INPUT="nixpkgs"
FLAKE_OUTPUT=".#devShells.x86_64-linux.all"

# Build the old output and get its store path.
OLD_STORE_PATH=$(nix build --show-trace --no-link --print-out-paths "$FLAKE_OUTPUT")

# Update flake.
nix flake update "$INPUT"

# Build the new output and get its store path.
NEW_STORE_PATH=$(nix build --show-trace --no-link --print-out-paths "$FLAKE_OUTPUT")

# Show git diff of flake.lock.
echo -e "\n===== flake.lock diff ====="
git diff flake.lock || true

# Show package version changes.
nix store diff-closures "$OLD_STORE_PATH" "$NEW_STORE_PATH"

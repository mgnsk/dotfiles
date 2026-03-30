#!/bin/env bash

set -eu

INPUT=$(nix flake metadata --json 2>/dev/null | gojq -r '.locks.nodes.root.inputs | keys[]' | fzf)
FLAKE_OUTPUT=".#devShells.x86_64-linux.$(nix flake show --json 2>/dev/null | gojq -r '.devShells."x86_64-linux" | keys[]' | fzf)"

# Build the old output and get its store path.
OLD_STORE_PATH=$(nix build --show-trace --no-link --print-out-paths "$FLAKE_OUTPUT")

# Update flake.
nix flake update "$INPUT"

# Build the new output and get its store path.
NEW_STORE_PATH=$(nix build --show-trace --no-link --print-out-paths "$FLAKE_OUTPUT")

# Show package version changes.
nix store diff-closures "$OLD_STORE_PATH" "$NEW_STORE_PATH"

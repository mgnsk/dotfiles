#!/bin/env bash

set -eu

mapfile -t INPUTS < <(nix flake metadata --json 2>/dev/null | jq -r '.locks.nodes.root.inputs | keys[]' | fzf --multi)
FLAKE_OUTPUT=".#devShells.x86_64-linux.$(nix flake show --json 2>/dev/null | jq -r '.devShells."x86_64-linux" | keys[]' | fzf)"

# Build the old output and get its store path.
OLD_STORE_PATH=$(nix build --show-trace --no-link --print-out-paths "$FLAKE_OUTPUT")

for input in "${INPUTS[@]}"; do
	echo "Updating $input"

	old_store_path=$(nix flake archive --json | jq -r --arg input "$input" '.inputs[$input].path')
	nix flake update "$input"
	new_store_path=$(nix flake archive --json | jq -r --arg input "$input" '.inputs[$input].path')

	# Show input repo changes.
	git diff --no-index "$old_store_path" "$new_store_path" || true
done

# Build the new output and get its store path.
NEW_STORE_PATH=$(nix build --show-trace --no-link --print-out-paths "$FLAKE_OUTPUT")

# Show package version changes.
nix store diff-closures "$OLD_STORE_PATH" "$NEW_STORE_PATH"

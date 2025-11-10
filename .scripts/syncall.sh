#!/bin/env bash

set -eu

for f in $(git -C "$HOME" ls-tree -r master --name-only | grep 'sync.sh'); do
	dir=$(dirname "$HOME/$f")
	echo ""
	echo "#### Running sync.sh in $dir"
	cd "$dir"
	bash sync.sh
done

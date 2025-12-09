#!/bin/env bash

set -eu

# Clean up built files from pkgbuild repos.
for d in ~/.pkgbuilds/*/; do
	echo "# Cleaning $d"
	git -C "$d" clean -xdf || true
done

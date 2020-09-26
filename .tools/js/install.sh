#!/bin/bash

set -e

yarn

dir="$HOME/.config/coc/extensions"

if test ! -d "$dir/node_modules"; then
	mkdir -p $dir
	ln -s $PWD/node_modules $dir/node_modules
fi

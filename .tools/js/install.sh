#!/bin/bash

set -e

yarn

if test ! -d $HOME/.config/coc/extensions/node_modules; then
	ln -s $PWD/node_modules $HOME/.config/coc/extensions/node_modules
fi

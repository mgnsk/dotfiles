#!/bin/bash

set -e

. ~/.env

function do_install {
	cd "$(dirname "$1")"
	echo "### Installing: $1"
	bash "$1"
}

export -f do_install

function install_tools {
	#find ~/.tools/*/install.sh -maxdepth 1 -print0 | parallel -k -u --halt-on-error 2 -0 -j"$(nproc)" do_install {}
	find ~/.tools/*/install.sh -maxdepth 1 -exec bash -c 'set -e; do_install "$0"' {} \;
}

install_tools

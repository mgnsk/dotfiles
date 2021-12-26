#!/bin/bash

set -e

function do_install {
	set -e
	cd "$(dirname "$1")"
	echo "### Installing: $1"
	bash "$1"
}

export -f do_install

find ~/.tools/*/install.sh -maxdepth 1 -exec bash -c 'do_install "$0"' {} \;

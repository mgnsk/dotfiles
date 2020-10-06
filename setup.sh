#!/bin/bash

set -e

. ~/.env

for dir in `ls -d ~/.tools/*/`; do
	echo "### Installing: $dir"
	cd $dir
	bash install.sh
done

#!/bin/bash

set -e

pip3 install --upgrade --no-cache-dir \
	yamllint \
	ansible-lint \
	vim-vint \
	proselint \
	i3ipc \
	tlacli

pip3 install --no-cache-dir https://github.com/containers/podman-compose/archive/devel.tar.gz

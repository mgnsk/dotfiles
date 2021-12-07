#!/bin/bash

set -e

pip3 install --upgrade --no-cache-dir \
	yamllint \
	ansible-lint \
	vim-vint \
	proselint \
	tlacli

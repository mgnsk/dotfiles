#!/bin/bash

set -e

fzf_dir=~/.fzf
if [ -d $fzf_dir ]; then
	cd $fzf_dir && git pull
else
	git clone --depth 1 https://github.com/junegunn/fzf.git $fzf_dir
fi

~/.fzf/install --all
echo "FZF version: $(fzf --version)"

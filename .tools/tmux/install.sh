#!/bin/bash

set -e

tpm_dir=~/.tmux/plugins/tpm
if [ -d $tpm_dir ]; then
	cd $tpm_dir && git pull
else
	git clone --depth 1 https://github.com/tmux-plugins/tpm $tpm_dir
fi

export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins/tpm"

~/.tmux/plugins/tpm/bin/install_plugins

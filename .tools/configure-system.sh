#!/usr/bin/env bash

set -euo pipefail

# Generate locales.
echo "en_US.UTF-8 UTF-8" | sudo tee /etc/locale.gen
echo "LANG=en_US.UTF-8" | sudo tee /etc/locale.conf
sudo locale-gen

install-tusk-completion() {
	# Prevent tusk from modifying .bashrc.
	cp "$HOME/.bashrc" "$HOME/.bashrc.bak"
	~/go/bin/tusk --install-completion bash
	mv "$HOME/.bashrc.bak" "$HOME/.bashrc"
}

install-tusk-completion

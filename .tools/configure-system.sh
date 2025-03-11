#!/usr/bin/env bash

set -euo pipefail

# TODO: make this dynamic in bashrc without requiring separate file
install-tusk-completion() {
	# Prevent tusk from modifying .bashrc.
	cp "$HOME/.bashrc" "$HOME/.bashrc.bak"
	tusk --install-completion bash
	mv "$HOME/.bashrc.bak" "$HOME/.bashrc"
}

install-tusk-completion

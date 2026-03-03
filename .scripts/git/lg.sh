#!/bin/env bash

set -eu

git log --color --graph --decorate --pretty="format:$GIT_LOG_PRETTY_FORMAT" --abbrev-commit --all |
	python3 ~/.scripts/git/relative_date.py |
	less -R

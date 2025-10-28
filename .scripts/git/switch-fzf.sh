#!/bin/env bash

set -eu

branch=$(
	git branch -v --sort=-committerdate |
		grep -v "^\*" |            # Without current branch.
		sed 's/^[[:space:]]*//g' | # Trim whitespace prefix.
		fzf --no-sort --height 20% --accept-nth=1
)

git switch "$branch"

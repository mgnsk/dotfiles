#!/bin/env bash

set -eu

branches=$(
	git branch -v --sort=-committerdate |
		grep -v "^\*" |            # Without current branch.
		sed 's/^[[:space:]]*//g' | # Trim whitespace prefix.
		fzf --multi --no-sort --height 20% --accept-nth=1
)

OIFS="$IFS"
IFS=$'\n'
for branch in $branches; do
	git branch -D "$branch"
done
IFS="$OIFS"

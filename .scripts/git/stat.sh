#!/bin/env bash

set -eu

# Local main branch.
main=$(git branch -l main master --format '%(refname:short)')

if [ -z "$main" ]; then
	echo "Error: Could not find a 'main' or 'master' branch." >&2
	exit 1
fi

# Iterate over all local branches and show their stats relative to the main branch.
{
	git branch --sort=-committerdate --format '%(refname:short)' | grep -vE "^(${main})$" | while IFS= read -r branch; do
		# Left: behind, right: ahead.
		# Handle cases where branches might not have a direct common history with main
		# by defaulting to "0 0" if rev-list fails or returns empty.
		stats=$(git rev-list --left-right --count "${main}...${branch}" 2>/dev/null || echo "0 0")

		behind=$(echo "$stats" | awk '{print $1}')
		ahead=$(echo "$stats" | awk '{print $2}')

		echo "$branch|$ahead ahead $behind behind $main"
	done
} | column -t -s '|'

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
	if [ $# -gt 0 ]; then
		branches="$1"
	else
		branches=$(git branch --sort=-committerdate --format '%(refname:short)' | grep -vE "^(${main})$")
	fi

	echo "$branches" | while IFS= read -r branch; do
		# Left: behind, right: ahead.
		rev_stats=$(git rev-list --left-right --count "${main}...${branch}" 2>/dev/null | awk '{a=$1; b=$2} END {printf "%d ahead %d behind", b+0, a+0}')
		diff_stats=$(git diff "${main}...${branch}" --numstat 2>/dev/null | awk '{add+=$1; del+=$2} END {printf "\033[32m+%d\033[0m \033[31m-%d\033[0m", add, del}')

		echo "$branch|$rev_stats $main|$diff_stats"
	done
} | column -t -s '|'

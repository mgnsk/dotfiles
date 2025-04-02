#!/bin/env bash

set -euo pipefail

# Pick desired files from a chosen branch.

# use fzf to choose source branch to snag files FROM
# TODO sort branches by changes in this specific directory
branch="$(git for-each-ref --sort='-committerdate' --format='%(refname:short)' refs/heads | fzf --no-sort --height 20%)"

# avoid doing work if branch isn't set
if test -n "$branch"; then
	# use fzf to choose files that differ from current branch
	files="$(git diff --relative --name-only "$branch" | fzf --no-sort --height 20% --layout=reverse --border --multi)"
fi

# avoid checking out branch if files aren't specified
if test -n "$files"; then
	git checkout -p "$branch" ${files[@]}
fi

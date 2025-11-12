#!/bin/env bash

set -eu

# Local main branch.
main=$(git branch -l main master --format '%(refname:short)')

# Local dev branch.
current=$(git branch --show-current)

# Left: behind, right: ahead.
stats=$(git rev-list --left-right --count "${main}...${current}")

behind=$(echo "$stats" | awk '{print $1}')
ahead=$(echo "$stats" | awk '{print $2}')

echo "$current: $ahead commits ahead of and $behind commits behind $main"

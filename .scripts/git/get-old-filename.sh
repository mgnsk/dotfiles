#!/bin/env bash

commit="$1"
file="$2"

if [[ -z "$commit" || -z "$file" ]]; then
	echo "Usage: $0 <commit> <current/path/to/file>" >&2
	exit 1
fi

# Loop through commits starting from newest. Get the filename at the specified commit,
# following through all renames.
# This is necessary since `git show` doesn't support the `--follow` flag.
git log --follow --name-status --pretty=format:"%h" -- "$file" |
	awk -v target="$commit" -v cur="$file" '
BEGIN { filename=cur }
# If line is a commit hash.
/^[0-9a-f]{7,40}$/ {
  commit=$0
  if(commit==target) {
    print filename
    exit
  }
  next
}
# If line is a rename.
/^R[0-9]+/ {
  old=$2
  new=$3
  if (new == filename) filename=old
}
'

#!/bin/env bash

# Opens a commit page.
#
# It's the same as `gh browse <commit-hash>` but
# doesn't interpret all-numeric hashes as issue numbers
# and does not depend on gh.

repo_url=$(git config --get remote.origin.url)
regex_https="https:\/\/github\.com\/(.+)\/(.+)\.git"
regex_ssh="git@github\.com:(.+)\/(.+)\.git"

if [[ $repo_url =~ $regex_https ]]; then
	owner="${BASH_REMATCH[1]}"
	repo="${BASH_REMATCH[2]}"
	xdg-open "https://github.com/${owner}/${repo}/commit/$1"
elif [[ $repo_url =~ $regex_ssh ]]; then
	owner="${BASH_REMATCH[1]}"
	repo="${BASH_REMATCH[2]}"
	xdg-open "https://github.com/${owner}/${repo}/commit/$1"
else
	exit 1
fi

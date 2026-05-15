#!/bin/env bash

# Prints Github repo owner/repo.

repo_url=$(git config --get remote.origin.url)
regex_https="https:\/\/github\.com\/(.+)\/(.+)\.git"
regex_ssh="git@github\.com:(.+)\/(.+)\.git"

if [[ $repo_url =~ $regex_https ]]; then
	owner="${BASH_REMATCH[1]}"
	repo="${BASH_REMATCH[2]}"
	echo "${owner}/${repo}"
elif [[ $repo_url =~ $regex_ssh ]]; then
	owner="${BASH_REMATCH[1]}"
	repo="${BASH_REMATCH[2]}"
	echo "${owner}/${repo}"
else
	exit 1
fi

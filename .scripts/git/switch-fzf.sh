#!/bin/env bash

set -euo pipefail

branch=$(git for-each-ref --sort='-committerdate' --format='%(refname:short)' refs/heads | fzf --no-sort --height 20%)

git switch "$branch"

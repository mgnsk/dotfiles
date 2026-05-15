#!/bin/env bash

# Opens a commit page.
#
# It's the same as `gh browse <commit-hash>` but
# doesn't interpret all-numeric hashes as issue numbers
# and does not depend on gh.

set -e

repo="$(git view-repo)"

xdg-open "https://github.com/${repo}/commit/$1"

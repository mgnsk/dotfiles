#!/bin/env bash

# Opens a commit page.
# It's the same as `gh browse <commit-hash>` but
# doesn't interpret all-numeric hashes as issue numbers.

xdg-open "https://github.com/$(gh repo view --json owner,name -q '.owner.login + "/" + .name')/commit/$1"

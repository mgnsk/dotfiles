#!/bin/env bash

set -eu

# Squash all commits into a single commit.

message="$1"

git reset "$(git commit-tree 'HEAD^{tree}' -m "$message")"

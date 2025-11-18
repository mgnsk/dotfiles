#!/bin/env bash

set -eu

git log --graph --decorate --pretty=format:"$GIT_LOG_PRETTY_FORMAT" --abbrev-commit --all

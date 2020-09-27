#!/bin/bash

set -e

yarn install --frozen-lockfile

cd ~/.config/coc/extensions

yarn install --frozen-lockfile

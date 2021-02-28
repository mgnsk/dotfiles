#!/bin/bash

set -e

npm config set prefix "$HOME/.npm-global"

export PATH="$HOME/.npm-global/bin:$PATH"

npm install -g yarn

yarn install --frozen-lockfile

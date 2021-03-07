#!/bin/bash

set -e

npm config set prefix "$HOME/.npm-global"

npm install -g yarn

~/.npm-global/bin/yarn install --frozen-lockfile

#!/bin/bash

set -e

NPM_CONFIG_PREFIX="$HOME/.npm-global" npm install -g yarn

yarn install --frozen-lockfile

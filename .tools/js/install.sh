#!/bin/bash

set -e

npm config set prefix "$HOME/.npm-global"

npm ci

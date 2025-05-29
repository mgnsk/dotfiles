#!/usr/bin/env bash

set -euo pipefail

nix build '.?submodules=1#docker'
./result | docker load
rm result

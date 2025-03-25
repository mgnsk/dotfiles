#!/usr/bin/env bash

set -euo pipefail

nix build '.?submodules=1#docker'
docker load <result
rm result

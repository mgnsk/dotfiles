#!/usr/bin/env bash

set -euo pipefail

nix build .#docker
docker load <result
rm result

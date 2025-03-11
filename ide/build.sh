#!/usr/bin/env bash

set -euo pipefail

docker build \
	--build-arg uid=1000 \
	--build-arg gid=1000 \
	--build-arg user=ide \
	--build-arg group=ide \
	-t ghcr.io/mgnsk/ide:edge \
	.

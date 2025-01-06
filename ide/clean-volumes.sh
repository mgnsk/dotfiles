#!/usr/bin/env bash

set -euo pipefail

for vol in $(docker volume ls --filter "name=ide" --quiet); do
	docker volume rm "$vol"
done

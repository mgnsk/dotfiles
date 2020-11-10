#!/bin/bash

set -euo pipefail
cat tools.go | grep _ | awk -F'"' '{print $2}' | xargs -tI % go get %
go clean -modcache

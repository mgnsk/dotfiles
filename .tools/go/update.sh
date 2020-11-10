#!/bin/bash

set -euo pipefail
cat tools.go | grep _ | awk -F'"' '{print $2}' | xargs -tI % go get -u %
go clean -modcache

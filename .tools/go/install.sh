#!/bin/bash

set -euo pipefail

go install $(awk '/import\s\(/{flag=1;next}/)/{flag=0}flag' tools.go | cut -d \" -f2)
go clean -modcache

machine=$(uname -m)
if [[ "$machine" == 'armv8l' ]]; then
	echo "### Skipping golangci-lint"
	exit 0
fi

curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.31.0
golangci-lint --version

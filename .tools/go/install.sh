#!/bin/bash

set -euo pipefail

go install $(awk '/import\s\(/{flag=1;next}/)/{flag=0}flag' tools.go | cut -d \" -f2)
go clean -modcache

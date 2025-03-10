#!/usr/bin/env bash

set -euo pipefail

# Add tools with go get -tool [PACKAGE]

go install -trimpath -v tool

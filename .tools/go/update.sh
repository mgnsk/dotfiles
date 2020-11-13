#!/bin/bash

set -euo pipefail

rm go.mod go.sum
go mod init tools
bash ./install.sh

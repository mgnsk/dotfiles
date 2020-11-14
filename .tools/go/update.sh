#!/bin/bash

set -e

rm -f go.mod go.sum
go mod init tools
bash ./install.sh

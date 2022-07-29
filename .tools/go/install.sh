#!/bin/bash

set -e

go install -v github.com/rliebz/tusk@latest

cd tools
go install -v ./...

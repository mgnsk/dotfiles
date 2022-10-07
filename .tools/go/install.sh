#!/bin/bash

set -e

go install -v github.com/rliebz/tusk@latest
go install -v github.com/golang/mock/mockgen@latest
go install -v github.com/goccmack/gocc@latest

cd tools
go install -v ./...

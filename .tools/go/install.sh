#!/bin/bash

set -e

go install -v github.com/rliebz/tusk@latest
go install -v github.com/golang/mock/mockgen@latest

cd tools
go install -v ./...

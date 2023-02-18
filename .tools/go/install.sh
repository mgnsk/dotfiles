#!/bin/bash

set -e

go install -v github.com/rliebz/tusk@latest
go install -v github.com/golang/mock/mockgen@latest
go install -v github.com/goccmack/gocc@latest
go install -v golang.org/x/tools/cmd/godoc@latest
go install -v github.com/golang/protobuf/protoc-gen-go@latest
go install -v google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

cd tools
go install -v ./...

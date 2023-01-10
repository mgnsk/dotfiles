#!/bin/bash

set -e

go install -v github.com/rliebz/tusk@latest
go install -v github.com/golang/mock/mockgen@latest
go install -v github.com/goccmack/gocc@latest
go install -v golang.org/x/tools/gopls@latest
go install -v golang.org/x/tools/cmd/goimports@latest
go install -v golang.org/x/tools/cmd/godoc@latest
go install -v github.com/mgechev/revive@latest
go install -v github.com/golang/protobuf/protoc-gen-go@latest
go install -v google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
go install -v github.com/golangci/golangci-lint/cmd/golangci-lint@latest
go install -v github.com/bufbuild/buf/cmd/buf@latest

cd tools
go install -v ./...

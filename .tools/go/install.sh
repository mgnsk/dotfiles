#!/bin/bash

set -e

go install -v github.com/go-delve/delve/cmd/dlv@latest
go install -v github.com/golang/mock/mockgen@latest
go install -v github.com/mgechev/revive@latest
go install -v github.com/golangci/golangci-lint/cmd/golangci-lint@latest
go install -v github.com/rliebz/tusk@latest
go install -v github.com/uber/prototool/cmd/prototool@latest
go install -v golang.org/x/tools/cmd/godoc@latest
go install -v golang.org/x/tools/cmd/goimports@latest
go install -v golang.org/x/tools/cmd/guru@latest
go install -v golang.org/x/tools/gopls@latest
go install -v mvdan.cc/sh/v3/cmd/shfmt@latest
go install -v github.com/mgnsk/templatetool@latest

cd tools
go install -v ./...

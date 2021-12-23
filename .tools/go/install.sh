#!/bin/bash

set -e

go install github.com/go-delve/delve/cmd/dlv@latest
go install github.com/golang/mock/mockgen@latest
go install github.com/mgechev/revive@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
go install github.com/rliebz/tusk@latest
go install github.com/uber/prototool/cmd/prototool@latest
go install golang.org/x/tools/cmd/godoc@latest
go install golang.org/x/tools/cmd/goimports@latest
go install golang.org/x/tools/cmd/guru@latest
go install golang.org/x/tools/gopls@latest
go install mvdan.cc/sh/v3/cmd/shfmt@latest
go install github.com/mgnsk/templatetool@latest

cd tools
go install ./...

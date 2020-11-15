// +build tools

package tools

// This is the best practice for go tools as modules.
// https://github.com/golang/go/wiki/Modules#how-can-i-track-tool-dependencies-for-a-module
import (
	_ "github.com/go-delve/delve/cmd/dlv"
	_ "github.com/golang/mock/mockgen"
	_ "github.com/golangci/golangci-lint/cmd/golangci-lint"
	_ "github.com/rliebz/tusk"
	_ "github.com/uber/prototool/cmd/prototool"
	_ "golang.org/x/tools/cmd/goimports"
	_ "golang.org/x/tools/cmd/guru"
	_ "golang.org/x/tools/gopls"
)

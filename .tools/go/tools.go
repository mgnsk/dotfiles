// +build tools

package tools

// This is the best practice for go tools as modules.
// https://github.com/golang/go/wiki/Modules#how-can-i-track-tool-dependencies-for-a-module
import (
	_ "arp242.net/goimport"
	_ "arp242.net/gosodoff"
	_ "github.com/davidrjenni/reftools/cmd/fillstruct"
	_ "github.com/fatih/gomodifytags"
	_ "github.com/fatih/motion"
	_ "github.com/go-delve/delve/cmd/dlv"
	_ "github.com/gogo/protobuf/protoc-gen-gogoslick"
	_ "github.com/golang/mock/mockgen"
	_ "github.com/golangci/golangci-lint/cmd/golangci-lint"
	_ "github.com/josharian/impl"
	_ "github.com/rliebz/tusk"
	_ "github.com/uber/prototool/cmd/prototool"
	_ "golang.org/x/tools/cmd/goimports"
	_ "golang.org/x/tools/cmd/gorename"
	_ "golang.org/x/tools/cmd/guru"
	_ "golang.org/x/tools/gopls"
)

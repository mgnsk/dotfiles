#!/usr/bin/env bash

set -euo pipefail

go install -v github.com/rliebz/tusk@latest
go install -v github.com/goccmack/gocc@latest
go install -v github.com/mgnsk/sway-fader@latest
go install -v golang.org/x/tools/cmd/deadcode@latest
go install -v golang.org/x/tools/cmd/godoc@latest
go install -v golang.org/x/tools/gopls@latest
go install -v golang.org/x/tools/cmd/goimports@latest
go install -v github.com/mgechev/revive@latest
go install -v github.com/mgnsk/gh-tpl@latest
go install -v github.com/itchyny/gojq/cmd/gojq@latest

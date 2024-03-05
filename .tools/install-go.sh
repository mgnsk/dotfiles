#!/usr/bin/env bash

set -euo pipefail

go install -v github.com/rliebz/tusk@latest
go install -v github.com/goccmack/gocc@latest
go install -v github.com/mgnsk/sway-fader@latest
go install -v golang.org/x/tools/cmd/deadcode@latest
go install -v github.com/mgechev/revive@latest

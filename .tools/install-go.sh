#!/usr/bin/env bash

set -euo pipefail

go install -v github.com/rliebz/tusk@latest
go install -v github.com/goccmack/gocc@latest
go install -v github.com/mgnsk/sway-fader@latest
go install -v github.com/mgnsk/gh-tpl@latest
go install -v github.com/itchyny/gojq/cmd/gojq@latest
go install -v github.com/grafana/jsonnet-language-server@latest

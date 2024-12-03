#!/usr/bin/env bash

set -euo pipefail

go install -v github.com/rliebz/tusk@latest
go install -v github.com/goccmack/gocc@latest
go install -v github.com/inspirer/textmapper/cmd/textmapper@main
go install -v github.com/mgnsk/sway-fader@latest
go install -v github.com/mgnsk/gh-tpl@latest
go install -v github.com/grafana/jsonnet-language-server@latest

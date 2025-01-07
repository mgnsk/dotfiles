#!/usr/bin/env bash

set -euo pipefail

go install -trimpath -v github.com/rliebz/tusk@latest
go install -trimpath -v github.com/goccmack/gocc@master
go install -trimpath -v github.com/inspirer/textmapper/cmd/textmapper@main
go install -trimpath -v github.com/mgnsk/sway-fader@latest
go install -trimpath -v github.com/mgnsk/gh-tpl@latest
go install -trimpath -v github.com/grafana/jsonnet-language-server@latest

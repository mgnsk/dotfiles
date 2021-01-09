#!/bin/bash
set -eou pipefail

earlyoom &>/dev/null &

exec "$@"

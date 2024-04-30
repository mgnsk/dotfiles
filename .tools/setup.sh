#!/usr/bin/env bash

set -euo pipefail

bash install-system.sh
bash install-go.sh
bash install-rust.sh
bash install-js.sh
bash install-php.sh
bash install-nvim.sh
bash install-fish.sh

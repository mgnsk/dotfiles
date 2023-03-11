#!/usr/bin/env bash

set -euo pipefail

composer install --no-dev --no-cache --no-interaction --optimize-autoloader

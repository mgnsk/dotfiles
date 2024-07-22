#!/usr/bin/env bash

set -euo pipefail

/usr/bin/composer install --no-dev --no-cache --no-interaction --optimize-autoloader

echo "extension=pdo_sqlite" | sudo tee /etc/php/conf.d/01-pdo_sqlite.ini

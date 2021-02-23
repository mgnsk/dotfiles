#!/bin/bash

set -euo pipefail

grep _ tools.go | awk -F'"' '{print $2}' | xargs -tI % go get %

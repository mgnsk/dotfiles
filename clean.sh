#!/bin/bash

set -e

source .env

find ~/.tools -type f -iname "remove.sh" -exec bash {} \;

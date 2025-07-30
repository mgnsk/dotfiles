#!/bin/env bash

set -eu

buildah rm -a
buildah rmi -a -f
podman system prune -a --volumes
podman image prune -a
rm -rf "$HOME/.local/share/containers"

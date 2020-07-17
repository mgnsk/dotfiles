#!/bin/bash
buildah rm -a
buildah rmi -a
podman system prune -a
podman image prune -a

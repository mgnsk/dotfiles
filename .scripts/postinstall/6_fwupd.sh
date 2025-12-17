#!/bin/env bash

set -eu

sudo fwupdmgr refresh
sudo fwupdmgr get-updates
sudo fwupdmgr update

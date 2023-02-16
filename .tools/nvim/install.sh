#!/bin/bash

set -e

nvim --headless -c "Lazy! install" -c "qa!"

#!/bin/env bash

set -e

cue=$(fzf --prompt "Select cue> ")
flac=$(fzf --prompt "Select flac> ")

cuebreakpoints "$cue" | shnsplit -o flac "$flac"
cuetag.sh "$cue" split-*.flac

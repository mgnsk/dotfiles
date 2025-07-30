#!/bin/env bash

steamos-readonly disable

function cleanup {
	steamos-readonly enable
}

trap cleanup EXIT

pacman-key --init
pacman-key --populate archlinux holo
pacman -Syy
pacman -S realtime-privileges
gpasswd -a deck realtime

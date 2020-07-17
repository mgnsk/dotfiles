#!/bin/bash

for kernel in $(pacman -Qqe | grep "^linux" | sed -En "s/-headers//p")
do
	mkinitcpio -p $kernel
done

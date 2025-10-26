#!/bin/env bash

set -eu

if lspci -k | grep -q i915; then
	echo "Detected Intel GPU (i915)"
	deps=$(ldd /usr/lib/libvulkan_intel.so)
elif lspci -k | grep -q amdgpu; then
	echo "Detected AMD GPU (amdgpu)"
	deps=$(ldd /usr/lib/libvulkan_radeon.so)
else
	echo "Unsupported GPU!"
	exit 1
fi

if echo "$deps" | grep -q "not found"; then
	echo "Missing Vulkan dependencies:"
	echo "$deps" | grep "not found"
	exit 1
fi

if ! vulkaninfo &>/dev/null; then
	vulkaninfo
	exit 1
fi

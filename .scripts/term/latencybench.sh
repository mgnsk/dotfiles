#!/bin/env bash

# Simple benchmark using date and a loop
iterations=1000
start=$(date +%s%N)
for ((_ = 0; _ < iterations; _++)); do echo -n "x" | cat >/dev/null; done
end=$(date +%s%N)
echo "Average latency per iteration: $(((end - start) / iterations)) nanoseconds"

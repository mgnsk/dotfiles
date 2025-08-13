#!/bin/env

# number of seconds to inhibit per cycle
inhibit_duration=25

# number of seconds to wait between cycles
sleep_duration=5

while true; do
	if pactl list | grep -q RUNNING; then
		echo "INHIBITING" >&2
		systemd-inhibit \
			--what idle \
			--who audio-idle-inhibit \
			--why "audio playing" \
			--mode block \
			sh -c "sleep $inhibit_duration"
	else
		echo "WAITING" >&2
		sleep $sleep_duration
	fi
done

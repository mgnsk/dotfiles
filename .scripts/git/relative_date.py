"""Format git log line with short relative date."""

import sys
import time

now = int(time.time())
ANSI_RED = "\033[31m"
ANSI_RESET = "\033[0m"

for line in sys.stdin:
    words = line.rstrip("\n").split("\x1f")

    # Second column is Unix timestamp.
    ago = max(0, now - int(words[1]))
    unit = "s"

    if ago < 60:
        unit = "s"
    elif ago < 3600:  # minutes
        ago = ago // 60
        unit = "m"
    elif ago < 86400:  # hours
        ago = ago // 3600
        unit = "h"
    elif ago < 2592000:  # days
        ago = ago // 86400
        unit = "d"
    elif ago < 31536000:  # months
        ago = ago // 2592000
        unit = "mo"
    else:  # years
        ago = ago // 31536000
        unit = "y"

    words[1] = f"{ANSI_RED}{ago}{unit}{ANSI_RESET}"
    print(" ".join(words))

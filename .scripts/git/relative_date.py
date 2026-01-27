"""Format git log line with short relative date."""

import sys
import time

now = int(time.time())
ANSI_RED = "\033[31m"
ANSI_RESET = "\033[0m"

for line in sys.stdin:
    words = line.rstrip("\n").split("\x1f")
    # Second column is Unix timestamp.
    words[1] = max(0, now - int(words[1]))
    if words[1] < 60:
        words[1] = f"{words[1]}s"
    elif words[1] < 3600:
        words[1] = f"{words[1]//60}m"
    elif words[1] < 86400:
        words[1] = f"{words[1]//3600}h"
    elif words[1] < 2592000:
        words[1] = f"{words[1]//86400}d"
    elif words[1] < 31536000:
        words[1] = f"{words[1]//2592000}mo"
    else:
        words[1] = f"{words[1]//31536000}y"

    words[1] = f"{ANSI_RED}{words[1]}{ANSI_RESET}"
    print(" ".join(words))

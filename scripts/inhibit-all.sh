#!/bin/bash
systemd-inhibit --what="shutdown:sleep:idle:handle-power-key:handle-suspend-key:handle-hibernate-key:handle-lid-switch" "$@"

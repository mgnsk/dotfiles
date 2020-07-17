#!bin/bash

for i in {3..20}
do
        if rfkill list | grep -q yes; then
                rfkill unblock wifi
        fi
        sleep 3
done


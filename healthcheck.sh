#!/bin/ash
wget --quiet --tries=1 --spider "https://${HOSTNAME}:8181/headphones/home" --no-check-certificate || exit 1
exit 0
#!/bin/ash
wget --quiet --tries=1 --no-check-certificate --spider "https://${HOSTNAME}:8181/headphones/home" || exit 1
exit 0
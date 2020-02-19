#!/bin/ash

if [ "$(nc -z "$(hostname -i)" 8181; echo $?)" -ne 0 ]; then
   echo "Headphones WebUI not responding on port 8181"
   exit 1
fi

echo "Headphones WebUI responding on port 8181"
exit 0
#!/bin/ash

if [ "$(netstat -plnt | grep -c 8181)" -ne 1 ]; then
   echo "Headphones WebUI not responding on port 8181"
   exit 1
fi

if [ "$(hostname -i 2>/dev/null | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | wc -l)" -eq 0 ]; then
   echo "NIC missing"
   exit 1
fi

echo "Headphones WebUI responding on port 8181"
exit 0
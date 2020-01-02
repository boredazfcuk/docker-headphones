#!/bin/ash
if [ -z "${STACKUSER}" ]; then
   STACKUSER="stackman"
   STACKPASS="Skibidibbydibyodadubdub"
fi
EXITCODE="$(wget --quiet --tries=1 --spider --no-check-certificate --user="${STACKUSER}" --password="${STACKPASSWORD}" "https://${HOSTNAME}:8181/headphones/home" && echo ${?})"
if [ "${EXITCODE}" != 0 ]; then
   echo "WebUI not responding: Error ${EXITCODE}"
   exit 1
fi
echo "WebUIs available"
exit 0
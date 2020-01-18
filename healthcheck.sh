#!/bin/ash
if [ -z "${stack_user}" ]; then
   stack_user="stackman"
   stack_pass="Skibidibbydibyodadubdub"
fi
exit_code="$(wget --quiet --tries=1 --spider --no-check-certificate --user="${stack_user}" --password="${stack_password}" "https://${HOSTNAME}:8181/headphones/home" && echo ${?})"
if [ "${exit_code}" != 0 ]; then
   echo "WebUI not responding: Error ${exit_code}"
   exit 1
fi
echo "WebUIs available"
exit 0
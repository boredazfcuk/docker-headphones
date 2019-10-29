#!/bin/ash

##### Functions #####
Initialise(){
   LANIP="$(hostname -i)"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    ***** Starting rembo10/headphones container *****"
   if [ -z "${USER}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: User name not set, defaulting to 'user'"; USER="user"; fi
   if [ -z "${UID}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: User ID not set, defaulting to '1000'"; UID="1000"; fi
   if [ -z "${GROUP}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Group name not set, defaulting to 'group'"; GROUP="group"; fi
   if [ -z "${GID}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Group ID not set, defaulting to '1000'"; GID="1000"; fi
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local user: ${USER}:${UID}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local group: ${GROUP}:${GID}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Headphones application directory: ${APPBASE}"
   sed -i "s%http_host =.*$%http_host = ${LANIP}%" "${CONFIGDIR}/headphones.ini"  
}

CreateGroup(){
   if [ -z "$(getent group "${GROUP}" | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Group ID available, creating group"
      addgroup -g "${GID}" "${GROUP}"
   elif [ ! "$(getent group "${GROUP}" | cut -d: -f3)" = "${GID}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   Group GID mismatch - exiting"
      exit 1
   fi
}

CreateUser(){
   if [ -z "$(getent passwd "${USER}" | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    User ID available, creating user"
      adduser -s /bin/ash -H -D -G "${GROUP}" -u "${UID}" "${USER}"
   elif [ ! "$(getent passwd "${USER}" | cut -d: -f3)" = "${UID}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   User ID already in use - exiting"
      exit 1
   fi
}

SetOwnerAndGroup(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Correct owner and group of application files, if required"
   find "${CONFIGDIR}" ! -user "${USER}" -exec chown "${USER}" {} \;
   find "${CONFIGDIR}" ! -group "${GROUP}" -exec chgrp "${GROUP}" {} \;
   find "${APPBASE}" ! -user "${USER}" -exec chown "${USER}" {} \;
   find "${APPBASE}" ! -group "${GROUP}" -exec chgrp "${GROUP}" {} \;
}

LaunchHeadphones(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Starting Headphones as ${USER}"
   su -m "${USER}" -c 'python '"${APPBASE}/Headphones.py"' --datadir '"${CONFIGDIR}"' --config '"${CONFIGDIR}/headphones.ini"''
}

##### Script #####
Initialise
CreateGroup
CreateUser
SetOwnerAndGroup
LaunchHeadphones

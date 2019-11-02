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
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Headphones configuration directory: ${CONFIGDIR}"
   sed -i "s%http_host =.*$%http_host = ${LANIP}%" "${CONFIGDIR}/headphones.ini"

   if [ ! -f "${CONFIGDIR}/https" ]; then mkdir -p "${CONFIGDIR}/https"; fi
   if [ ! -f "${CONFIGDIR}/https/headphones.crt" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Generate private key for encrypting communications"
      openssl ecparam -genkey -name secp384r1 -out "${CONFIGDIR}/https/headphones.key"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Create certificate request"
      openssl req -new -subj "/C=NA/ST=Global/L=Global/O=Headphones/OU=Headphones/CN=Headphones/" -key "${CONFIGDIR}/https/headphones.key" -out "${CONFIGDIR}/https/headphones.csr"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Generate self-signed certificate request"
      openssl x509 -req -sha256 -days 3650 -in "${CONFIGDIR}/https/headphones.csr" -signkey "${CONFIGDIR}/https/headphones.key" -out "${CONFIGDIR}/https/headphones.crt"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure Headphones to use ${CONFIGDIR}/https/headphones.key key file"
      HEADPHONESKEY="$(sed -nr '/\[General\]/,/\[/{/^https_key =/p}' "${CONFIGDIR}/headphones.ini")"
      sed -i "s%^${HEADPHONESKEY}$%https_key = ${CONFIGDIR}/https/headphones.key%" "${CONFIGDIR}/headphones.ini"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure Headphones to use ${CONFIGDIR}/https/headphones.crt certificate file"
      HEADPHONESCERT="$(sed -nr '/\[General\]/,/\[/{/^https_cert =/p}' "${CONFIGDIR}/headphones.ini")"
      sed -i "s%^${HEADPHONESCERT}$%https_cert = ${CONFIGDIR}/https/headphones.crt%" "${CONFIGDIR}/headphones.ini"
      HEADPHONESHTTPS="$(sed -nr '/\[General\]/,/\[/{/^enable_https =/p}' "${CONFIGDIR}/headphones.ini")"
      sed -i "s%^${HEADPHONESHTTPS}$%enable_https = 1%" "${CONFIGDIR}/headphones.ini"
   fi

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

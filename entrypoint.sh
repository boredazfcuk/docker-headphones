#!/bin/ash

##### Functions #####
Initialise(){
   lan_ip="$(hostname -i)"
   default_gateway="$(ip route | grep "^default" | awk '{print $3}')"
   echo
   echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : ***** Configuring Headphones container launch environment *****"
   echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : $(cat /etc/*-release | grep "PRETTY_NAME" | sed 's/PRETTY_NAME=//g' | sed 's/"//g')"
   echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Local user: ${stack_user:=stackman}:${stack_uid:=1000}"
   echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Local group: ${headphones_group:=headphones}:${headphones_group_id:=1000}"
   echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Password: ${stack_password:=Skibidibbydibyodadubdub}"
   echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Headphones application directory: ${app_base_dir}"
   echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Headphones configuration directory: ${config_dir}"
   echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Listening IP Address: ${lan_ip}"
   echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Docker host LAN IP subnet: ${host_lan_ip_subnet}"
   if [ -z "${music_dirs}" ]; then
      echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Music library location: ${music_dirs:=/storage/music/}"
   else
      echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Music library location: ${music_dirs%%,*}"
   fi
}

CheckPIANextGen(){
   if [ "${pianextgen_enabled}" ]; then
      echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : PIANextGen is enabled. Wait for VPN to connect"
      vpn_adapter="$(ip addr | grep tun.$ | awk '{print $7}')"
      while [ -z "${vpn_adapter}" ]; do
         vpn_adapter="$(ip addr | grep tun.$ | awk '{print $7}')"
         sleep 5
      done
      echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : VPN adapter available: ${vpn_adapter}"
   else
      echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : PIANextGen shared network stack is not enabled, configure container forwarding mode mode"
      pianextgen_host="$(getent hosts pianextgen | awk '{print $1}')"
      echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : PIANextGen container IP address: ${pianextgen_host}"
      echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Create default route via ${pianextgen_host}"
      ip route del default 
      ip route add default via "${pianextgen_host}"
      echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Create additional route to Docker host network ${host_lan_ip_subnet} via ${default_gateway}"
      ip route add "${host_lan_ip_subnet}" via "${default_gateway}"
   fi
}

CreateGroup(){
   if [ "$(grep -c "^${headphones_group}:x:${headphones_group_id}:" "/etc/group")" -eq 1 ]; then
      echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Group, ${headphones_group}:${headphones_group_id}, already created"
   else
      if [ "$(grep -c "^${headphones_group}:" "/etc/group")" -eq 1 ]; then
         echo "$(date '+%d-%b-%Y %T') - ERROR :: Entrypoint : Group name, ${headphones_group}, already in use - exiting"
         sleep 120
         exit 1
      elif [ "$(grep -c ":x:${headphones_group_id}:" "/etc/group")" -eq 1 ]; then
         if [ "${force_gid}" = "True" ]; then
            group="$(grep ":x:${headphones_group_id}:" /etc/group | awk -F: '{print $1}')"
            echo "$(date '+%d-%b-%Y %T') - WARNING :: Entrypoint : Group id, ${headphones_group_id}, already exists - continuing as force_gid variable has been set. Group name to use: ${headphones_group}"
         else
            echo "$(date '+%d-%b-%Y %T') - ERROR :: Entrypoint : Group id, ${headphones_group_id}, already in use - exiting"
            sleep 120
            exit 1
         fi
      else
         echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Creating group ${headphones_group}:${headphones_group_id}"
         addgroup -g "${headphones_group_id}" "${headphones_group}"
      fi
   fi
}

CreateUser(){
   if [ "$(grep -c "^${stack_user}:x:${stack_uid}:${headphones_group_id}" "/etc/passwd")" -eq 1 ]; then
      echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : User, ${stack_user}:${stack_uid}, already created"
   else
      if [ "$(grep -c "^${stack_user}:" "/etc/passwd")" -eq 1 ]; then
         echo "$(date '+%d-%b-%Y %T') - ERROR :: Entrypoint : User name, ${stack_user}, already in use - exiting"
         sleep 120
         exit 1
      elif [ "$(grep -c ":x:${stack_uid}:$" "/etc/passwd")" -eq 1 ]; then
         echo "$(date '+%d-%b-%Y %T') - ERROR :: Entrypoint : User id, ${stack_uid}, already in use - exiting"
         sleep 120
         exit 1
      else
         echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Creating user ${stack_user}:${stack_uid}"
         adduser -s /bin/ash -D -G "${headphones_group}" -u "${stack_uid}" "${stack_user}" -h "/home/${stack_user}"
      fi
   fi
}

FirstRun(){
   echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : First run detected - create default config"
   find "${config_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${config_dir}" ! -group "${headphones_group}" -exec chgrp "${headphones_group}" {} \;
   su -p "${stack_user}" -c "python ${app_base_dir}/Headphones.py --datadir ${config_dir} --config ${config_dir}/headphones.ini --nolaunch --quiet --daemon --pidfile /tmp/headphones.pid"
   sleep 15
   echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : ***** Reload Headphones launch environment *****"
   pkill python
   sleep 5
   echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Set git path: /usr/bin/git"
   echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Disable git statup check"
   echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Configure update interval to 48hr"
   echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Set encoder type to: lame"
   sed -i \
      -e "/^\[General\]/,/^\[.*\]/ s%^git_path =.*%git_path = /usr/bin/git%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^check_github =.*%check_github = 1%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^check_github_on_startup =.*%check_github_on_startup = 0%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^check_github_interval =.*%check_github_interval = 1440%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^encoder =.*%encoder = lame%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^encoder_path =.*%encoder_path = /usr/bin/lame%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^auto_add_artists =.*%auto_add_artists = 1%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^add_album_art =.*%add_album_art = 1%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^embed_album_art =.*%embed_album_art = 1%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^autowant_upcoming =.*%autowant_upcoming = 1%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^libraryscan =.*%libraryscan = 1%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^libraryscan_interval = .*%libraryscan_interval = 24%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^download_scan_interval = .*%download_scan_interval = 60%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^update_db_interval = .*%update_db_interval = 24%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^wait_until_release_date =.*%wait_until_release_date = 1%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^official_releases_only =.*%official_releases_only = 1%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^autowant_manually_added =.*%autowant_manually_added = 1%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^prefer_torrents =.*%prefer_torrents = 0%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^ignore_clean_releases =.*%ignore_clean_releases = 1%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^add_album_art =.*%add_album_art = 0%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^preferred_quality =.*%preferred_quality = 1%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^rename_files =.*%rename_files = 1%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^move_files =.*%move_files = 1%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^cleanup_files =.*%cleanup_files = 1%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^replace_existing_folders =.*%replace_existing_folders = 1%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^correct_metadata =.*%correct_metadata = 1%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^file_format =.*%file_format = {\$Disc-}\$Track - \$Artist - \$Album - \$Title%" \
      -e "/^\[Songkick\]/,/^\[.*\]/ s%^songkick_enabled =.*%songkick_enabled = 0%" \
      "${config_dir}/headphones.ini"
   sleep 1
}

Configure(){
   echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Disable browser launch on startup"
   echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Configure host IP: ${lan_ip}"
   echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Set Music library path: ${music_dirs}"
   echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Enable API key: ${global_api_key}"
   sed -i \
      -e "/^\[General\]/,/^\[.*\]/ s%^http_host =.*%http_host = ${lan_ip}%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^http_username =.*%http_username = ${stack_user}%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^http_password =.*%http_password = ${stack_password}%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^launch_browser =.*%launch_browser = 0%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^music_dir =.*%music_dir = ${music_dirs}%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^destination_dir =.*%destination_dir = ${music_dirs}%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^api_key =.*%api_key = ${global_api_key}%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^api_enabled =.*%api_enabled = 1%" \
      "${config_dir}/headphones.ini"
   if getent hosts headphones >/dev/null 2>&1; then
      sed -i "s%^http_root =.*%http_root = /headphones%" "${config_dir}/headphones.ini"
   fi
}

Kodi(){
   if getent hosts kodi >/dev/null 2>&1; then
      echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Configure Kodi"
      sed -i \
         -e "/^\[XBMC\]/,/^\[.*\]/ s%^xbmc_update =.*%xbmc_update = 1%" \
         -e "/^\[XBMC\]/,/^\[.*\]/ s%^xbmc_notify =.*%xbmc_notify = 1%" \
         -e "/^\[XBMC\]/,/^\[.*\]/ s%^xbmc_username =.*%xbmc_username = ${kodi_username:=kodi}%" \
         -e "/^\[XBMC\]/,/^\[.*\]/ s%^xbmc_enabled =.*%xbmc_enabled = 1%" \
         -e "/^\[XBMC\]/,/^\[.*\]/ s%^xbmc_password =.*%xbmc_password = ${kodi_password:=kodi}%" \
         -e "/^\[XBMC\]/,/^\[.*\]/ s%^xbmc_host =.*%xbmc_host = http://${kodi_host:=kodi}:${kodi_port:=8080}%" \
         "${config_dir}/headphones.ini"
   else
      sed -i \
      -e "/^\[XBMC\]/,/^\[.*\]/ s%^xbmc_enabled =.*%xbmc_enabled = 0%" \
      "${config_dir}/headphones.ini"
   fi
}

Deluge(){
   if getent hosts deluge >/dev/null 2>&1; then
      echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Configure Deluge"
      sed -i \
         -e "/^\[General\]/,/^\[.*\]/ s%^torrentblackhole_dir =.*%torrentblackhole_dir = ${deluge_watch_dir}%" \
         -e "/^\[General\]/,/^\[.*\]/ s%^download_torrent_dir =.*%download_torrent_dir = ${deluge_incoming_dir}%" \
         -e "/^\[General\]/,/^\[.*\]/ s%^keep_torrent_files =.*%keep_torrent_files = 1%" \
         -e "/^\[General\]/,/^\[.*\]/ s%^keep_torrent_files_dir =.*%keep_torrent_files_dir = ${deluge_file_backup_dir}%" \
         -e "/^\[General\]/,/^\[.*\]/ s%^open_magnet_links =.*%open_magnet_links = 0%" \
         -e "/^\[General\]/,/^\[.*\]/ s%^magnet_links =.*%magnet_links = 1%" \
         -e "/^\[General\]/,/^\[.*\]/ s%^numberofseeders =.*%numberofseeders = 1%" \
         -e "/^\[General\]/,/^\[.*\]/ s%^torrent_downloader =.*%torrent_downloader = 3%" \
         -e "/^\[Deluge\]/,/^\[.*\]/ s%^deluge_host =.*%deluge_host = http://deluge:8112/%" \
         -e "/^\[Deluge\]/,/^\[.*\]/ s%^deluge_label =.*%deluge_label = music%" \
         -e "/^\[Deluge\]/,/^\[.*\]/ s%^deluge_password =.*%deluge_password = ${stack_password}1%" \
         -e "/^\[Deluge\]/,/^\[.*\]/ s%^deluge_done_directory =.*%deluge_done_directory = ${music_complete_dir}%" \
         -e "/^\[Piratebay\]/,/^\[.*\]/ s%^piratebay =.*%piratebay = 1%" \
         -e "/^\[Piratebay\]/,/^\[.*\]/ s%^piratebay_ratio =.*%piratebay_ratio = 1%" \
         "${config_dir}/headphones.ini"
   fi
}

SABnzbd(){
   if getent hosts sabnzbd >/dev/null 2>&1; then
      echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Configure SABnzbd"
      sed -i \
         -e "/^\[General\]/,/^\[.*\]/ s%^nzb_downloader =.*%nzb_downloader = 0%" \
         -e "/^\[General\]/,/^\[.*\]/ s%^download_dir =.*%download_dir = ${music_complete_dir}%" \
         -e "/^\[General\]/,/^\[.*\]/ s%^blackhole_dir =.*%blackhole_dir = ${sabnzbd_watch_dir}%" \
         -e "/^\[SABnzbd\]/,/^\[.*\]/ s%^sab_host =.*%sab_host = http://sabnzbd:9090/sabnzbd%" \
         -e "/^\[SABnzbd\]/,/^\[.*\]/ s%^sab_category =.*%sab_category = music%" \
         -e "/^\[SABnzbd\]/,/^\[.*\]/ s%^sab_apikey =.*%sab_apikey = ${global_api_key}%" \
         -e "/^\[SABnzbd\]/,/^\[.*\]/ s%^sab_username =.*%sab_username = ${stack_user}%" \
         -e "/^\[SABnzbd\]/,/^\[.*\]/ s%^sab_password =.*%sab_password = ${stack_password}%" \
         "${config_dir}/headphones.ini"
   fi
}

Airsonic(){
   if getent hosts airsonic >/dev/null 2>&1; then
      echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Configure Airsonic"
      sed -i \
         -e "/^\[Subsonic\]/,/^\[.*\]/ s%^subsonic_host =.*%subsonic_host = http://airsonic:4040/airsonic/%" \
         -e "/^\[Subsonic\]/,/^\[.*\]/ s%^subsonic_enabled =.*%subsonic_enabled = 1%" \
         -e "/^\[Subsonic\]/,/^\[.*\]/ s%^subsonic_username =.*%subsonic_username = ${stack_user}%1" \
         -e "/^\[Subsonic\]/,/^\[.*\]/ s%^subsonic_password =.*%subsonic_password = ${stack_password}1%" \
         "${config_dir}/headphones.ini"
   else
      sed -i \
         -e "/^\[Subsonic\]/,/^\[.*\]/ s%^subsonic_enabled =.*%subsonic_enabled = 0%" \
         "${config_dir}/headphones.ini"
   fi
}

Prowl(){
   if [ "${prowl_api_key}" ]; then
      echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Configuring Prowl notifications"
      sed -i \
         -e "/^\[Prowl\]/,/^\[.*\]/ s%^prowl_enabled =.*%prowl_enabled = 1%" \
         -e "/^\[Prowl\]/,/^\[.*\]/ s%^prowl_keys =.*%prowl_keys = ${prowl_api_key}%" \
         -e "/^\[Prowl\]/,/^\[.*\]/ s%^prowl_onsnatch =.*%prowl_onsnatch = 1%" \
         "${config_dir}/headphones.ini"
   else
      sed -i \
         -e "/^\[Prowl\]/,/^\[.*\]/ s%^prowl_enabled =.*%prowl_enabled = 0%" \
         "${config_dir}/headphones.ini"
   fi
}

Telegram(){
   if [ "${telegram_token}" ] && [ "${telegram_chat_id}" ]; then
      echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Configuring Telegram notifications"
      sed -i \
         -e "/^\[Telegram\]/,/^\[.*\]/ s%^telegram_enabled =.*%telegram_enabled = 1%" \
         -e "/^\[Telegram\]/,/^\[.*\]/ s%^telegram_token =.*%telegram_token = ${telegram_token}%" \
         -e "/^\[Telegram\]/,/^\[.*\]/ s%^telegram_onsnatch =.*%telegram_onsnatch = 1%" \
         -e "/^\[Telegram\]/,/^\[.*\]/ s%^telegram_userid =.*%telegram_userid = ${telegram_chat_id}%" \
         "${config_dir}/headphones.ini"
   else
      sed -i \
         -e "/^\[Telegram\]/,/^\[.*\]/ s%^telegram_enabled =.*%telegram_enabled = 0%" \
         "${config_dir}/headphones.ini"
   fi
}

OMGWTFNZBs(){
   if [ "${omgwtfnzbs_user}" ]; then
      echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Configuring OMGWTFNZBs search provider"
      sed -i \
         -e "/^\[omgwtfnzbs\]/,/^\[.*\]/ s%^omgwtfnzbs =.*%omgwtfnzbs = 1%" \
         -e "/^\[omgwtfnzbs\]/,/^\[.*\]/ s%^omgwtfnzbs_uid =.*%omgwtfnzbs_uid = ${omgwtfnzbs_user}%" \
         -e "/^\[omgwtfnzbs\]/,/^\[.*\]/ s%^omgwtfnzbs_apikey =.*%omgwtfnzbs_apikey = ${omgwtfnzbs_api_key}%" \
         "${config_dir}/headphones.ini"
   else
      sed -i \
         -e "/^\[omgwtfnzbs\]/,/^\[.*\]/ s%^omgwtfnzbs =.*%omgwtfnzbs = 0%" \
         "${config_dir}/headphones.ini"
   fi
}

MusicBrainz(){
   if getent hosts musicbrainz >/dev/null 2>&1; then
      echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Configure MusicBrainz"
      sed -i \
         -e "s%^mirror =.*%mirror = custom%" \
         -e "s%^customsleep =.*%customsleep = 1%" \
         -e "s%^customhost =.*%customhost = musicbrainz%" \
         "${config_dir}/headphones.ini"
      while [ "$(nc -z musicbrainz 5000; echo $?)" -ne 0 ]; do
         echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Waiting for the MusicBrainz web page to come online..."
         sleep 10
      done
   else
      sed -i \
         -e "s%^mirror =.*%mirror = musicbrainz.org%" \
         "${config_dir}/headphones.ini"
   fi
}

SetOwnerAndGroup(){
   echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Correct owner and group of application files, if required"
   find "${config_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${config_dir}" ! -group "${headphones_group}" -exec chgrp "${headphones_group}" {} \;
   find "${app_base_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${app_base_dir}" ! -group "${headphones_group}" -exec chgrp "${headphones_group}" {} \;
}

LaunchHeadphones(){
   echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : ***** Configuration of Headphones container launch environment complete *****"
   echo "$(date '+%d-%b-%Y %T') - INFO :: Entrypoint : Starting Headphones as ${stack_user}"
   exec "$(which su)" -p "${stack_user}" -c "$(which python) ${app_base_dir}/Headphones.py --datadir ${config_dir} --config ${config_dir}/headphones.ini"
}

##### Script #####
Initialise
CheckPIANextGen
CreateGroup
CreateUser
if [ ! -f "${config_dir}/headphones.ini" ]; then FirstRun; fi
Configure
Kodi
Deluge
SABnzbd
Airsonic
Prowl
Telegram
OMGWTFNZBs
MusicBrainz
SetOwnerAndGroup
LaunchHeadphones

#!/bin/ash

##### Functions #####
Initialise(){
   lan_ip="$(hostname -i)"
   echo -e "\n"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    ***** Starting rembo10/headphones container *****"
   if [ -z "${stack_user}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: User name not set, defaulting to 'stackman'"; stack_user="stackman"; fi
   if [ -z "${stack_password}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Password not set, defaulting to 'Skibidibbydibyodadubdub'"; stack_password="Skibidibbydibyodadubdub"; fi   
   if [ -z "${user_id}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: User ID not set, defaulting to '1000'"; user_id="1000"; fi
   if [ -z "${group}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Group name not set, defaulting to 'group'"; group="group"; fi
   if [ -z "${group_id}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Group ID not set, defaulting to '1000'"; group_id="1000"; fi
   if [ -z "${music_dirs}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Music library path not set, defaulting to '/storage/music/'"; else music_dirs="${music_dirs%%,*}"; fi
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local user: ${stack_user}:${user_id}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local group: ${group}:${group_id}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Headphones application directory: ${app_base_dir}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Headphones configuration directory: ${config_dir}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Music library path: ${music_dirs}"
}

CreateGroup(){
   if [ -z "$(getent group "${group}" | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Group ID available, creating group"
      addgroup -g "${group_id}" "${group}"
   elif [ ! "$(getent group "${group}" | cut -d: -f3)" = "${group_id}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   Group group_id mismatch - exiting"
      exit 1
   fi
}

CreateUser(){
   if [ -z "$(getent passwd "${stack_user}" | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    User ID available, creating user"
      adduser -s /bin/ash -H -D -G "${group}" -u "${user_id}" "${stack_user}"
   elif [ ! "$(getent passwd "${stack_user}" | cut -d: -f3)" = "${user_id}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   User ID already in use - exiting"
      exit 1
   fi
}

FirstRun(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    First run detected - create default config"
   find "${config_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${config_dir}" ! -group "${group}" -exec chgrp "${group}" {} \;
   su -m "${stack_user}" -c "python ${app_base_dir}/Headphones.py --datadir ${config_dir} --config ${config_dir}/headphones.ini --nolaunch --quiet --daemon --pidfile /tmp/headphones.pid"
   sleep 15
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    ***** Reload rembo10/headphones *****"
   pkill python
   sleep 5
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Set git path: /usr/bin/git"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Disable git statup check"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure update interval to 48hr"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Set encoder type to: lame"
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

EnableSSL(){
   if [ ! -f "${config_dir}/https" ]; then 
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure Headphones to use HTTPS"
      mkdir -p "${config_dir}/https"
      openssl ecparam -genkey -name secp384r1 -out "${config_dir}/https/headphones.key"
      openssl req -new -subj "/C=NA/ST=Global/L=Global/O=Headphones/OU=Headphones/CN=Headphones/" -key "${config_dir}/https/headphones.key" -out "${config_dir}/https/headphones.csr"
      openssl x509 -req -sha256 -days 3650 -in "${config_dir}/https/headphones.csr" -signkey "${config_dir}/https/headphones.key" -out "${config_dir}/https/headphones.crt" >/dev/null 2>&1
      sed -i \
         -e "/^\[General\]/,/^\[.*\]/ s%https_key =.*%https_key = ${config_dir}/https/headphones.key%" \
         -e "/^\[General\]/,/^\[.*\]/ s%https_cert =.*%https_cert = ${config_dir}/https/headphones.crt%" \
         -e "/^\[General\]/,/^\[.*\]/ s%enable_https =.*%enable_https = 1%" \
         "${config_dir}/headphones.ini"
   fi
}

Configure(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Disable browser launch on startup"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure host IP: ${lan_ip}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Set Music library path: ${music_dirs}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Enable API key: ${global_api_key}"
   sed -i \
      -e "/^\[General\]/,/^\[.*\]/ s%^http_host =.*%http_host = ${lan_ip}%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^http_username =.*%http_username = ${stack_user}%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^http_password =.*%http_password = ${stack_password}%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^launch_browser =.*%launch_browser = 0%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^music_dir =.*%music_dir = ${music_dirs}%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^destination_dir =.*%destination_dir = ${music_dirs}%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^api_key =.*%api_key = ${global_api_key}1%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^api_enabled =.*%api_enabled = 1%" \
      -e "/^\[General\]/,/^\[.*\]/ s%^enable_https =.*%enable_https = 1%" \
      "${config_dir}/headphones.ini"
   if [ ! -z "${headphones_enabled}" ]; then
      sed -i "s%^http_root =.*%http_root = /headphones%" "${config_dir}/headphones.ini"
   fi
   if [ ! -z "${kodi_group_id}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure Kodi Headless"
      sed -i \
         -e "/^\[XBMC\]/,/^\[.*\]/ s%^xbmc_update =.*%xbmc_update = 1%" \
         -e "/^\[XBMC\]/,/^\[.*\]/ s%^xbmc_notify =.*%xbmc_notify = 1%" \
         -e "/^\[XBMC\]/,/^\[.*\]/ s%^xbmc_username =.*%xbmc_username = kodi%" \
         -e "/^\[XBMC\]/,/^\[.*\]/ s%^xbmc_enabled =.*%xbmc_enabled = 1%" \
         -e "/^\[XBMC\]/,/^\[.*\]/ s%^xbmc_password =.*%xbmc_password = ${kodi_password}%" \
         -e "/^\[XBMC\]/,/^\[.*\]/ s%^xbmc_host =.*%xbmc_host = http://kodi:8080%" \
         "${config_dir}/headphones.ini"
   fi
   if [ ! -z "${deluge_enabled}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure Deluge"
      sed -i \
         -e "/^\[General\]/,/^\[.*\]/ s%^torrentblackhole_dir =.*%torrentblackhole_dir = ${deluge_watch_dir}%" \
         -e "/^\[General\]/,/^\[.*\]/ s%^download_torrent_dir =.*%download_torrent_dir = ${deluge_incoming_dir}%" \
         -e "/^\[General\]/,/^\[.*\]/ s%^keep_torrent_files =.*%keep_torrent_files = 1%" \
         -e "/^\[General\]/,/^\[.*\]/ s%^keep_torrent_files_dir =.*%keep_torrent_files_dir = ${deluge_file_backup_dir}%" \
         -e "/^\[General\]/,/^\[.*\]/ s%^open_magnet_links =.*%open_magnet_links = 0%" \
         -e "/^\[General\]/,/^\[.*\]/ s%^magnet_links =.*%magnet_links = 1%" \
         -e "/^\[General\]/,/^\[.*\]/ s%^numberofseeders =.*%numberofseeders = 1%" \
         -e "/^\[General\]/,/^\[.*\]/ s%^torrent_downloader =.*%torrent_downloader = 3%" \
         -e "/^\[Deluge\]/,/^\[.*\]/ s%^deluge_host =.*%deluge_host = https://deluge:8112/%" \
         -e "/^\[Deluge\]/,/^\[.*\]/ s%^deluge_label =.*%deluge_label = music%" \
         -e "/^\[Deluge\]/,/^\[.*\]/ s%^deluge_password =.*%deluge_password = ${stack_password}1%" \
         -e "/^\[Deluge\]/,/^\[.*\]/ s%^deluge_done_directory =.*%deluge_done_directory = ${music_complete_dir}%" \
         "${config_dir}/headphones.ini"
   fi
   if [ ! -z "${sabnzbd_enabled}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure SABnzbd"
      sed -i \
         -e "/^\[General\]/,/^\[.*\]/ s%^nzb_downloader =.*%nzb_downloader = 0%" \
         -e "/^\[General\]/,/^\[.*\]/ s%^download_dir =.*%download_dir = ${music_complete_dir}%" \
         -e "/^\[General\]/,/^\[.*\]/ s%^blackhole_dir =.*%blackhole_dir = ${sabnzbd_watch_dir}%" \
         -e "/^\[SABnzbd\]/,/^\[.*\]/ s%^sab_host =.*%sab_host = https://sabnzbd:9090/sabnzbd%" \
         -e "/^\[SABnzbd\]/,/^\[.*\]/ s%^sab_category =.*%sab_category = music%" \
         -e "/^\[SABnzbd\]/,/^\[.*\]/ s%^sab_apikey =.*%sab_apikey = ${global_api_key}%" \
         -e "/^\[SABnzbd\]/,/^\[.*\]/ s%^sab_username =.*%sab_username = ${stack_user}%" \
         -e "/^\[SABnzbd\]/,/^\[.*\]/ s%^sab_password =.*%sab_password = ${stack_password}%" \
         "${config_dir}/headphones.ini"
   fi
   if [ ! -z "${subsonic_enabled}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure Subsonic"
      sed -i \
         -e "/^\[Subsonic\]/,/^\[.*\]/ s%^subsonic_host =.*%subsonic_host = https://subsonic:4141/subsonic/index.view%" \
         -e "/^\[Subsonic\]/,/^\[.*\]/ s%^subsonic_enabled =.*%subsonic_enabled = 1%" \
         -e "/^\[Subsonic\]/,/^\[.*\]/ s%^subsonic_username =.*%subsonic_username = ${stack_user}%1" \
         -e "/^\[Subsonic\]/,/^\[.*\]/ s%^subsonic_password =.*%subsonic_password = ${stack_password}1%" \
         "${config_dir}/headphones.ini"
   fi
   if [ ! -z "${musicbrainz_code}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure MusicBrainz"
      sed -i -e "s%^mirror =.*%mirror = custom%" \
         -e "s%^customsleep =.*%customsleep = 1%" \
         -e "s%^customhost =.*%customhost = musicbrainz%" "${config_dir}/headphones.ini"
   fi
   if [ ! -z "${prowl_api_key}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configuring Prowl notifications"
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
   if [ ! -z "${omgwtfnzbs_user}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configuring OMGWTFNZBs search provider"
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

SetOwnerAndGroup(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Correct owner and group of application files, if required"
   find "${config_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${config_dir}" ! -group "${group}" -exec chgrp "${group}" {} \;
   find "${app_base_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${app_base_dir}" ! -group "${group}" -exec chgrp "${group}" {} \;
}

WaitForMusicBrainz(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local MusicBrainz server configured"
   #while [ "$(mysql --host=mariadb --user=kodi --password="${kodi_password}" --execute="SELECT User FROM mysql.user;" 2>/dev/null | grep -c kodi)" = 0 ]; do
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Waiting for MusicBrainz server to come online..." 
      sleep 10
   #done
}

LaunchHeadphones(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Starting Headphones as ${stack_user}"
   su -m "${stack_user}" -c "python ${app_base_dir}/Headphones.py --datadir ${config_dir} --config ${config_dir}/headphones.ini"
}

##### Script #####
Initialise
CreateGroup
CreateUser
if [ ! -f "${config_dir}/headphones.ini" ]; then FirstRun; fi
if [ ! -d "${config_dir}/https" ]; then EnableSSL; fi
Configure
SetOwnerAndGroup
#if [ ! -z "${musicbrainz_code}" ]; then WaitForMusicBrainz; fi
LaunchHeadphones

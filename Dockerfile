FROM alpine:3.10
MAINTAINER boredazfcuk
ARG app_dependencies="git python libxml2 libxslt-dev tzdata openssl wget lame py-openssl"
ARG app_repo="rembo10/headphones"
ENV app_base_dir="/Headphones" \
   config_dir="/config"

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD STARTED *****" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Add group, user and required directories" && \
   mkdir -p "${app_base_dir}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install application dependencies" && \
   apk add --no-cache --no-progress ${app_dependencies} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install ${app_repo}" && \
   git clone -b master "https://github.com/${app_repo}.git" "${app_base_dir}"

COPY start-headphones.sh /usr/local/bin/start-headphones.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | Set permissions on launch script" && \
   chmod +x /usr/local/bin/start-headphones.sh /usr/local/bin/healthcheck.sh && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD COMPLETE *****"

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s \
  CMD /usr/local/bin/healthcheck.sh

VOLUME "${config_dir}"
WORKDIR "${app_base_dir}"

CMD /usr/local/bin/start-headphones.sh

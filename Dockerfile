FROM alpine:latest
MAINTAINER boredazfcuk
ARG APPDEPENDENCIES="git python py2-lxml py-openssl libxslt-dev tzdata openssl wget lame"
ARG REPO="rembo10/headphones"
ENV APPBASE="/Headphones" \
   CONFIGDIR="/config"

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD STARTED *****" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Add group, user and required directories" && \
   mkdir -p "${APPBASE}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install application dependencies" && \
   apk add --no-cache --no-progress ${APPDEPENDENCIES} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install ${REPO}" && \
   git clone -b master "https://github.com/${REPO}.git" "${APPBASE}"

COPY start-headphones.sh /usr/local/bin/start-headphones.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | Set permissions on launch script" && \
   chmod +x /usr/local/bin/start-headphones.sh /usr/local/bin/healthcheck.sh && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD COMPLETE *****"

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s \
  CMD /usr/local/bin/healthcheck.sh

VOLUME "${CONFIGDIR}"
WORKDIR "${APPBASE}"

CMD /usr/local/bin/start-headphones.sh

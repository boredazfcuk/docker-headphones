FROM alpine:latest
MAINTAINER boredazfcuk
ENV APPBASE="/Headphones" \
   REPO="rembo10/headphones" \
   CONFIGDIR="/config" \
   APPDEPENDENCIES="git python py2-lxml py-openssl libxslt-dev tzdata"

COPY start-headphones.sh /usr/local/bin/start-headphones.sh

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD STARTED *****" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Add group, user and required directories" && \
   mkdir -p "${APPBASE}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install application dependencies" && \
   apk add --no-cache --no-progress ${APPDEPENDENCIES} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install ${REPO}" && \
   git clone -b master "https://github.com/${REPO}.git" "${APPBASE}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD COMPLETE *****"

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s \
  CMD wget --quiet --tries=1 --spider http://${HOSTNAME}:8181/headphones/home || exit 1

VOLUME "${CONFIGDIR}"

CMD /usr/local/bin/start-headphones.sh
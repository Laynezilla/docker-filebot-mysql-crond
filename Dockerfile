FROM alpine:latest

ENV PUID 1001
ENV PGID 1001
ENV PUSER filebot
ENV PGROUP filebot

COPY root/scripts/filebot_import.sh /scripts/filebot_import.sh
COPY root/etc/crontabs/filebot /etc/crontabs/$PUSER

RUN apk add --no-cache --virtual=build-dependencies --upgrade git && \
	apk add --no-cache --upgrade curl openjdk8 nano tar wget mysql-client && \
	apk del --purge build-dependencies && \
	rm -rf /root/.cache /tmp/* && \
	addgroup -g $PGID $PGROUP && \
	adduser -D -G $PGROUP -u $PUID $PUSER && \
	mkdir -p /config /data/music /log /scripts && \
	chown $PUSER:$PGROUP /config /data/music /log /scripts && \
	chmod 755 /config /data/music /log /scripts && \
	chmod 600 /etc/crontabs/$PUSER && \
	chmod 755 /scripts/beets_import.sh

USER $PUSER

RUN mkdir /filebot

WORKDIR /filebot

RUN sh -xu <<< "$(curl -fsSL https://raw.githubusercontent.com/filebot/plugins/master/installer/tar.sh)"

CMD ["crond", "-f", "-d", "8"]

VOLUME /config /data/music /log /scripts

WORKDIR /root

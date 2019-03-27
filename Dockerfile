FROM alpine:latest

ENV PUID 1001
ENV PGID 1001
ENV PUSER filebot
ENV PGROUP filebot

COPY root/scripts/beets_import.sh /scripts/beets_import.sh
COPY root/etc/crontabs/beets /etc/crontabs/$PUSER

RUN apk add --no-cache --virtual=build-dependencies --upgrade git && \
	apk add --no-cache --upgrade openjdk8 && \
	apk del --purge build-dependencies && \
	rm -rf /root/.cache /tmp/* && \
	addgroup -g $PGID $PGROUP && \
	adduser -D -G $PGROUP -u $PUID $PUSER && \
	mkdir -p /config /data/music /log /scripts && \
	chown $PUSER:$PGROUP /config /data/music /log /scripts && \
	chmod 755 /config /data/music /log /scripts && \
	chmod 600 /etc/crontabs/$PUSER && \
	chmod 755 /scripts/beets_import.sh

CMD ["crond", "-f", "-d", "8"]

VOLUME /config /data/music /log /scripts

WORKDIR /root

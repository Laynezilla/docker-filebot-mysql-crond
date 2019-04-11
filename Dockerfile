FROM openjdk:8-jre-alpine

ENV PUID 1001
ENV PGID 1001
ENV PUSER filebot
ENV PGROUP data
ENV FILEBOTDIR /filebot

COPY root /

RUN apk add --no-cache --upgrade curl file inotify-tools libzen mediainfo mysql-client nano nss shadow su-exec tar wget xz && \
	apk add --no-cache --upgrade --repository http://nl.alpinelinux.org/alpine/edge/testing chromaprint && \
	rm -rf /root/.cache /tmp/* && \
	addgroup -g $PGID $PGROUP && \
	adduser -D -G $PGROUP -u $PUID $PUSER && \
	mkdir -m 775 -p $FILEBOTDIR \
	/config \
	/data/television \
	/data/film \
	/log \
	/scripts && \
	chmod 755 /usr/local/bin/docker-entrypoint.sh /scripts/filebot_artwork.sh /scripts/filebot_import.sh /etc/crontabs/filebot

WORKDIR $FILEBOTDIR

RUN PACKAGE_VERSION=4.8.5 && \
	PACKAGE_FILE=FileBot_$PACKAGE_VERSION-portable.tar.xz && \
	PACKAGE_URL=https://get.filebot.net/filebot/FileBot_$PACKAGE_VERSION/$PACKAGE_FILE && \
	curl -o "$PACKAGE_FILE" -z "$PACKAGE_FILE" "$PACKAGE_URL" && \
	tar xvf "$PACKAGE_FILE" && \
	mv $FILEBOTDIR/lib/Linux-x86_64/libzen.so $FILEBOTDIR/lib/Linux-x86_64/libzen.so.broken && \
	ln -sf /usr/lib/libzen.so.0.4.37 $FILEBOTDIR/lib/Linux-x86_64/libzen.so && \
	ln -sf "$FILEBOTDIR/filebot.sh" /usr/local/bin/filebot

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["crond", "-f", "-d", "8"]

VOLUME /config /data/television /data/film /log /scripts

WORKDIR /root

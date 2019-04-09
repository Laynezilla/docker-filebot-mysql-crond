#!/bin/sh
# /usr/local/bin/docker-entrypoint.sh

if [ ! "id -u $PUSER" = $PUID ]
	usermod -u $PUID $PUSER
fi

if [ ! "id -g $PUSER" = $PGID ]
	groupmod -g $PGID $PGROUP
fi

chown -R $PUSER:$PGROUP $FILEBOTDIR /scripts
chown $PUSER:$PGROUP /config /data/television /data/film /log

if [ "$1" = 'crond' ]; then
	chmod 600 /etc/crontabs/$PUSER
	exec "$@"
else
	# does this command need to use exec?
	su-exec $PUSER:$PGROUP "$@"
fi

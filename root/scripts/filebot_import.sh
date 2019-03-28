#!/bin/sh
# /scripts/filebot_import.sh

# Set log path
log="/log/filebot_import.log"

# Set lockfile path
lockfile="/scripts/filebot_import.lock"

# Create lockfile containing PID. If file exists already script will exit
if ( set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null; then

	# Set trap to clean up lockfile in case of premature script end
	trap 'echo `date --rfc-3339=seconds` "ERROR: Script ended prematurely."  >> $log; rm -f "$lockfile"; exit $?' INT TERM
	
else
	echo `date --rfc-3339=seconds` "INFO: Lock exists, $lockfile owned by $(cat $lockfile). Exiting script."  >> $log
	exit 1
fi

# Set database variables
DB_HOST=$(awk '/mariadb/ {print $1}' /etc/hosts)

if [[ -z $DB_HOST ]]; then
	echo `date --rfc-3339=seconds` "ERROR: No database server in hosts file." >> $log
	rm -f "$lockfile"
	exit 1
fi

DB_USER='root'
DB_PASSWORD='E78GxcJYBUg6fjkG6jrFr6mkYtKX7IZn'
DB_PORT='3306'
DB_NAME='torrents'
DB_TABLE='metadata_queue'

# Check for server connection and database existance
if [[ $(ping -c1 $DB_HOST | sed -n 's/.*\([0-1]\) packets received.*/\1/p') = 1 ]]; then
	echo `date --rfc-3339=seconds` "INFO: Server found." >> /dev/null
	if ! mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASSWORD -e "USE $DB_NAME" &>/dev/null; then
		echo `date --rfc-3339=seconds` "ERROR: Could not connect to database." >> $log
		rm -f "$lockfile"
		exit 1
	else
		echo `date --rfc-3339=seconds` "INFO: Database connection successful." >> /dev/null
	fi
else
	echo `date --rfc-3339=seconds` "ERROR: Could not find server." >> $log
	rm -f "$lockfile"
	exit 1
fi

# Get lowest ID with a downloaded status
id=$(mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASSWORD -D $DB_NAME -s -N -e "SELECT id FROM $DB_TABLE WHERE status='downloaded' AND (type='film' OR type='television') ORDER BY id ASC LIMIT 1")

# While loop for as long as there is an id with a downloaded status
while [[ $id ]]; do
	
	# Pull variables based on id
	path=$(mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASSWORD -D $DB_NAME -s -N -e "SELECT path FROM $DB_TABLE WHERE id='$id'")
	
	if [[ ! -e "$path" ]]; then
		echo `date --rfc-3339=seconds` "ERROR: Path $path does not exist." >> $log
		mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASSWORD -D $DB_NAME -s -N -e "UPDATE $DB_TABLE SET status='failure' WHERE id='$id'"
		rm -f "$lockfile"
		exit 1
	fi
	
	subtype=$(mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASSWORD -D $DB_NAME -s -N -e "SELECT subtype FROM $DB_TABLE WHERE id='$id'")
	
	# Set status to processing
	mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASSWORD -D $DB_NAME -s -N -e "UPDATE $DB_TABLE SET status='processing' WHERE id='$id'"
	
	case $subtype in
		feature)
			if filebot -rename "$data_path" --action hardlink -non-strict --conflict override --db TheMovieDB -no-xattr --format "/mnt/mordor/film/feature/{n.normalize()} ({y})/{n.normalize()} ({y})" &>/dev/null; then
				status="success"
			else
				echo `date --rfc-3339=seconds` "WARNING: $path failed to import." >> $log
				status="failure"
			fi
			;;
		short)
			if filebot -rename "$data_path" --action hardlink -non-strict --conflict override --db TheMovieDB -no-xattr --format "/mnt/mordor/film/short/{n.normalize()} ({y})/{n.normalize()} ({y})" &>/dev/null; then
				status="success"
			else
				echo `date --rfc-3339=seconds` "WARNING: $path failed to import." >> $log
				status="failure"
			fi
			;;
		concert)
			if filebot -rename "$data_path" --action hardlink -non-strict --conflict override --db TheMovieDB -no-xattr --format "/mnt/mordor/film/concert/{n.normalize()} ({y})/{n.normalize()} ({y})" &>/dev/null; then
				status="success"
			else
				echo `date --rfc-3339=seconds` "WARNING: $path failed to import." >> $log
				status="failure"
			fi
			;;
		episode)
			if filebot -rename "$data_path" --action hardlink -non-strict --conflict override --db TheTVDB -no-xattr --format "/mnt/mordor/television/television/{n.normalize()}/{episode.special ? 'Special' : 'Season '+s.pad(2)}/{n.normalize()} - {episode.special ? 'S00E'+special.pad(2) : s00e00} - {t.normalize().replacePart(', Part $1')}" &>/dev/null; then
				status="success"
			else
				echo `date --rfc-3339=seconds` "WARNING: $path failed to import." >> $log
				status="failure"
			fi
			;;
		season)
			if filebot -rename "$data_path" --action hardlink -non-strict --conflict override --db TheTVDB -no-xattr --format "/mnt/mordor/television/television/{n.normalize()}/{episode.special ? 'Special' : 'Season '+s.pad(2)}/{n.normalize()} - {episode.special ? 'S00E'+special.pad(2) : s00e00} - {t.normalize().replacePart(', Part $1')}" &>/dev/null; then
				status="success"
			else
				echo `date --rfc-3339=seconds` "WARNING: $path failed to import." >> $log
				status="failure"
			fi
			;;
		special)
			if filebot -rename "$data_path" --action hardlink -non-strict --conflict override --db TheTVDB -no-xattr --format "/mnt/mordor/television/television/{n.normalize()}/{episode.special ? 'Special' : 'Season '+s.pad(2)}/{n.normalize()} - {episode.special ? 'S00E'+special.pad(2) : s00e00} - {t.normalize().replacePart(', Part $1')}" &>/dev/null; then
				status="success"
			else
				echo `date --rfc-3339=seconds` "WARNING: $path failed to import." >> $log
				status="failure"
			fi
			;;
		*)
			echo `date --rfc-3339=seconds` "WARNING: $path has subtype \"$subtype\" which has no action set up." >> $log
			status="failure"
			;;
	esac
	
	# Set status
	mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASSWORD -D $DB_NAME -s -N -e "UPDATE $DB_TABLE SET status='$status' WHERE id='$id'"
	
	# Get next lowest ID with a downloaded status. Should return null if there are no more
	id=$(mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASSWORD -D $DB_NAME -s -N -e "SELECT id FROM $DB_TABLE WHERE status='downloaded' AND (type='film' OR type='television') ORDER BY id ASC LIMIT 1")
	
done

# Clean up lockfile and end trap
rm -f "$lockfile"
trap - INT TERM

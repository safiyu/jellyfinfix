#!/bin/sh
figlet -w 120 -l Jellyfin_Fix
echo "Server started at $(date)"
CLEAN_CRON=$(echo "$CRON_STRING" | tr -d '"')
echo "Running cron job: $CLEAN_CRON"
echo "$CLEAN_CRON sh /app/entry.sh" > /app/crontab
crontab /app/crontab
cat /app/crontab
# start cron
/usr/sbin/crond -f -l 2
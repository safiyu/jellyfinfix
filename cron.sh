#!/bin/sh
figlet -w 120 -l Jellyfin_Fix
echo "Server started at $(date)"

MODE="${MODE:-watch}"
CLEAN_CRON=$(echo "${CRON_STRING:-0 */6 * * *}" | tr -d '"')

echo "Execution Mode: $MODE"

case "$MODE" in
    "cron")
        echo "Running cron job: $CLEAN_CRON"
        echo "$CLEAN_CRON sh /app/entry.sh" > /app/crontab
        crontab /app/crontab
        cat /app/crontab
        exec /usr/sbin/crond -f -l 2
        ;;
    "both")
        echo "Running cron job ($CLEAN_CRON) and real-time watcher"
        echo "$CLEAN_CRON sh /app/entry.sh" > /app/crontab
        crontab /app/crontab
        cat /app/crontab
        /usr/sbin/crond -l 2 &
        exec bash /app/watch.sh
        ;;
    "watch"|*)
        echo "Running real-time filesystem watcher"
        exec bash /app/watch.sh
        ;;
esac
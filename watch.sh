#!/bin/bash
set -u

DEBOUNCE_SECONDS="${DEBOUNCE_SECONDS:-10}"
LOCKFILE="/tmp/jellyfix.lock"
WATCH_DIR="/media"

echo "Starting real-time filesystem watcher on ${WATCH_DIR} (debounce: ${DEBOUNCE_SECONDS}s)"

# Execute scan with mutex lock to guarantee single-instance sequential processing
run_scan() {
    echo "Filesystem event triggered scan. Acquiring lock..."
    flock -x "$LOCKFILE" bash -c "cd ${WATCH_DIR} && bash /app/replace.sh" || true
}

# Perform initial scan on startup
run_scan

# Ignore metadata, subtitles, images, trickplay folders, and hidden system files
EXCLUDE_PATTERN='(\.ignore$|\.nfo$|\.xml$|\.jpg$|\.jpeg$|\.png$|\.srt$|\.sub$|\.idx$|\.trickplay|\.git|\.tmp|\.DS_Store|@eaDir)'

echo "Monitoring ${WATCH_DIR} strictly for video file and directory changes..."

inotifywait -m -r --exclude "$EXCLUDE_PATTERN" -e create,delete,move,close_write --format "%w%f" "$WATCH_DIR" 2>/dev/null | while read -r event_path; do
    # Only trigger scan if event is a video file or a non-excluded directory
    if [[ "$event_path" =~ \.(mkv|MKV|mp4|MP4|avi|AVI|mpg|MPG|mpeg|MPEG|mov|MOV|wmv|WMV|ts|TS)$ ]] || [ -d "$event_path" ]; then
        # Drain any queued events arriving within 1s to prevent redundant runs
        while read -r -t 1 _; do :; done

        echo "Video change detected ($event_path). Settling for ${DEBOUNCE_SECONDS}s before scanning..."
        sleep "$DEBOUNCE_SECONDS"

        run_scan
    fi
done

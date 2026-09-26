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

# Case-insensitive exclude pattern for inotifywait
EXCLUDE_PATTERN='(\.ignore|\.nfo|\.xml|\.jpg|\.jpeg|\.png|\.gif|\.bmp|\.webp|\.srt|\.sub|\.idx|\.bif|\.trickplay|\.git|\.tmp|\.ds_store|@eadir)'

echo "Monitoring ${WATCH_DIR} strictly for video file and user directory changes..."

inotifywait -m -r --excludei "$EXCLUDE_PATTERN" -e create,delete,move,close_write --format "%w%f" "$WATCH_DIR" 2>/dev/null | while read -r event_path; do
    shopt -s nocasematch
    
    IS_VIDEO_EVENT=0
    if [[ "$event_path" =~ \.(mkv|mp4|avi|mpg|mpeg|mov|wmv|ts)$ ]]; then
        IS_VIDEO_EVENT=1
    elif [ -d "$event_path" ]; then
        base_dir=$(basename "$event_path")
        if [[ "$base_dir" =~ \.trickplay$ ]] || [[ "$base_dir" =~ ^\. ]] || [ "$base_dir" = "@eaDir" ]; then
            IS_VIDEO_EVENT=0
        else
            IS_VIDEO_EVENT=1
        fi
    fi
    
    shopt -u nocasematch

    if [ "$IS_VIDEO_EVENT" -eq 1 ]; then
        # Drain queued events arriving within 1s to prevent redundant runs
        while read -r -t 1 _; do :; done

        echo "Video change detected ($event_path). Settling for ${DEBOUNCE_SECONDS}s before scanning..."
        sleep "$DEBOUNCE_SECONDS"

        run_scan
    fi
done

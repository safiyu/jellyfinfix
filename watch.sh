#!/bin/bash
set -euo pipefail

DEBOUNCE_SECONDS="${DEBOUNCE_SECONDS:-10}"
LOCKFILE="/tmp/jellyfix.lock"
WATCH_DIR="/media"

echo "Starting real-time filesystem watcher on ${WATCH_DIR} (debounce: ${DEBOUNCE_SECONDS}s)"

# Execute scan with mutex lock to guarantee single-instance sequential processing
run_scan() {
    echo "Filesystem event triggered scan. Waiting for lock..."
    flock -x "$LOCKFILE" bash -c "cd ${WATCH_DIR} && bash /app/replace.sh"
}

# Perform initial scan on startup
run_scan

# Monitor filesystem changes recursively
inotifywait -m -r -e create,delete,move,close_write --format "%w%f" "$WATCH_DIR" 2>/dev/null | while read -r _file; do
    # Drain any queued events arriving within 1s to prevent redundant runs
    while read -r -t 1 _; do :; done

    echo "Filesystem change detected. Settling for ${DEBOUNCE_SECONDS}s before scanning..."
    sleep "$DEBOUNCE_SECONDS"

    run_scan
done

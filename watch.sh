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

# Ignore .ignore files, hidden files, and temporary files to prevent self-triggering loops
EXCLUDE_PATTERN='(\.ignore$|/\.git/|/\.tmp|/\.DS_Store)'

echo "Monitoring ${WATCH_DIR} for media changes (ignoring .ignore files)..."

inotifywait -m -r --exclude "$EXCLUDE_PATTERN" -e create,delete,move,close_write --format "%w%f" "$WATCH_DIR" 2>/dev/null | while read -r event_file; do
    # Drain any queued events arriving within 1s to prevent rapid redundant runs
    while read -r -t 1 _; do :; done

    echo "Media change detected ($event_file). Settling for ${DEBOUNCE_SECONDS}s before scanning..."
    sleep "$DEBOUNCE_SECONDS"

    run_scan
done

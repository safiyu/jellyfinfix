#!/bin/bash
set -euo pipefail

LOCKFILE="/tmp/jellyfix.lock"

echo "Start: $(date)"
echo "Starting scan"

flock -x "$LOCKFILE" bash -c "cd /media && bash /app/replace.sh"

echo "Scan ended"
echo "End: $(date)"
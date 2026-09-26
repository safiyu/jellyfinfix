#!/bin/bash
set -euo pipefail

echo "Start: $(date)"
echo "Starting scan"
cd /media || exit 1
bash /app/replace.sh
echo "Scan ended"
echo "End: $(date)"
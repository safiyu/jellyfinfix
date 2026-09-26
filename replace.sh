#!/bin/bash
set -eu

# Traverse all directories safely (handling spaces in path names)
find . -type d -print0 | while IFS= read -r -d '' dir; do
    ignore_file="${dir}/.ignore"
    
    # Early-exit search: find first video file (use || true to handle SIGPIPE when head closes pipe)
    has_video=$(find "$dir" -type f \( -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" -o -name "*.mpg" -o -name "*.mpeg" -o -name "*.mov" -o -name "*.wmv" -o -name "*.ts" \) -print 2>/dev/null | head -n 1 || true)

    if [ -z "$has_video" ]; then
        if [ ! -f "$ignore_file" ]; then
            echo "$dir - No video file exists. Creating .ignore"
            touch "$ignore_file"
        fi
    else
        if [ -f "$ignore_file" ]; then
            echo "$dir - Video file exists. Removing .ignore"
            rm -f "$ignore_file"
        fi
    fi
done

# Trigger Jellyfin library refresh if parameters are set
if [ -n "${JF_URL:-}" ] && [ -n "${JF_API_KEY:-}" ]; then
    clean_url="${JF_URL%/}"
    jfurl="${clean_url}/library/refresh?api_key=${JF_API_KEY}"
    
    # Redact API key in stdout/logs to prevent secret exposure
    log_url="${clean_url}/library/refresh?api_key=***"
    echo "Calling Jellyfin endpoint: $log_url"
    
    curl -s -S -X POST -d "" \
        -H "Accept: application/json" \
        -H "Authorization: MediaBrowser Token=\"${JF_API_KEY}\"" \
        -H "X-Emby-Token: ${JF_API_KEY}" \
        -H "X-MediaBrowser-Token: ${JF_API_KEY}" \
        -w "jellyfin library refresh completed with http_code: %{http_code}\n" \
        "$jfurl"
fi